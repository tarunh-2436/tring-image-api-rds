import json
import os
from datetime import datetime, timezone
from urllib.parse import unquote_plus
import boto3
import logging

import pg8000
import redis

logger = logging.getLogger()
logger.setLevel(logging.INFO)

s3 = boto3.client("s3")
sns = boto3.client("sns")

DB_HOST = os.environ["DB_HOST"]
DB_PORT = int(os.environ.get("DB_PORT", "5432"))
DB_NAME = os.environ["DB_NAME"]
DB_USER = os.environ["DB_USER"]
DB_PASSWORD = os.environ["DB_PASSWORD"]

REDIS_HOST = os.environ["REDIS_HOST"]
REDIS_PORT = int(os.environ.get("REDIS_PORT", "6379"))

SNS_TOPIC_ARN = os.environ["SNS_TOPIC_ARN"]


def get_db_connection():
    return pg8000.connect(
        host=DB_HOST,
        port=DB_PORT,
        database=DB_NAME,
        user=DB_USER,
        password=DB_PASSWORD,
        timeout=5,
    )


def get_redis_client():
    return redis.Redis(
        host=REDIS_HOST,
        port=REDIS_PORT,
        ssl=True,
        decode_responses=True,
        socket_connect_timeout=5,
        socket_timeout=5,
    )


def lambda_handler(event, context):

    logger.info(json.dumps(event))

    for record in event["Records"]:
        try:
            body = json.loads(record["body"])
            if "Records" not in body:
                logger.info("Skipping S3 test event")
                continue
            process_record(record)
        except Exception as error:
            logger.exception(f"Failed to process record.")
            raise

    return {"statusCode": 200, "body": json.dumps({"message": "Processing complete"})}


def process_record(record):

    body = json.loads(record["body"])

    s3_record = body["Records"][0]

    bucket = s3_record["s3"]["bucket"]["name"]

    key = s3_record["s3"]["object"]["key"]

    key = unquote_plus(key)

    logger.info(
        "Processing %s/%s",
        bucket,
        key,
    )

    # userId/imageId/filename

    parts = key.split("/")

    if len(parts) != 4:
        raise ValueError(f"Unexpected S3 key format: {key}")

    user_id = parts[1]
    image_id = parts[2]
    filename = parts[3]

    metadata = s3.head_object(Bucket=bucket, Key=key)

    file_size = metadata["ContentLength"]
    content_type = metadata.get("ContentType", "unknown")

    extension = filename.rsplit(".", 1)[-1].lower()

    timestamp = datetime.now(timezone.utc)

    connection = None
    cursor = None

    try:

        connection = get_db_connection()

        cursor = connection.cursor()

        cursor.execute(
            """
            UPDATE images
            SET
                status = %s,
                file_size = %s,
                content_type = %s,
                extension = %s,
                processed_at = %s
            WHERE image_id = %s
            AND owner_id = %s
            """,
            (
                "COMPLETED",
                file_size,
                content_type,
                extension,
                timestamp,
                image_id,
                user_id,
            ),
        )

        connection.commit()

        logger.info("Updated metadata for image %s", image_id)

        if cursor.rowcount == 0:
            raise ValueError(f"Image {image_id} not found for owner {user_id}")

        try:

            redis_client = get_redis_client()

            redis_client.delete(f"image:{image_id}")

            logger.info(
                "Invalidated Redis cache: image:%s",
                image_id,
            )

        except Exception:

            logger.exception("Failed to invalidate Redis cache.")

    except Exception:

        logger.exception("Failed to update PostgreSQL.")

        if connection:
            connection.rollback()

        raise

    finally:

        if cursor:
            cursor.close()

        if connection:
            connection.close()

    sns.publish(
        TopicArn=SNS_TOPIC_ARN,
        Subject="Image Processed Successfully",
        Message=f"""
Image ID: {image_id}

Filename: {filename}

File Size: {file_size} bytes

Content Type: {content_type}

Extension: {extension}

Processed At: {timestamp.isoformat()}
""",
    )

    logger.info(
        "Successfully processed %s",
        image_id,
    )
