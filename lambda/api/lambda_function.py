import json
import logging
import os
import uuid
from datetime import datetime, timezone

import boto3
import pg8000
import redis

logger = logging.getLogger()
logger.setLevel(logging.INFO)

s3 = boto3.client("s3")

UPLOAD_BUCKET = os.environ["UPLOAD_BUCKET"]

DB_HOST = os.environ["DB_HOST"]
DB_PORT = int(os.environ.get("DB_PORT", "5432"))
DB_NAME = os.environ["DB_NAME"]
DB_USER = os.environ["DB_USER"]
DB_PASSWORD = os.environ["DB_PASSWORD"]

REDIS_HOST = os.environ["REDIS_HOST"]
REDIS_PORT = int(os.environ.get("REDIS_PORT", "6379"))


def response(status_code, body):
    return {
        "statusCode": status_code,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(body),
    }


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


def get_user_id(event):
    claims = event["requestContext"]["authorizer"]["jwt"]["claims"]
    return claims["sub"]


def lambda_handler(event, context):

    logger.info(
        "Received %s request for %s",
        event["requestContext"]["http"]["method"],
        event["requestContext"]["http"]["path"],
    )

    method = event["requestContext"]["http"]["method"]

    path = event["requestContext"]["http"]["path"]

    if method == "POST" and path.endswith("/images"):
        return create_image(event)

    if method == "GET" and path.endswith("/images"):
        return list_images(event)

    if method == "GET" and "/images/" in path:
        return get_image(event)

    return response(404, {"message": "Route not found"})


def create_image(event):

    user_id = get_user_id(event)

    try:
        body = json.loads(event["body"])

        filename = body["filename"]
        content_type = body["contentType"]

    except (KeyError, json.JSONDecodeError):

        return response(
            400,
            {"message": "Invalid request body"},
        )

    image_id = str(uuid.uuid4())

    timestamp = datetime.now(timezone.utc)

    connection = None
    cursor = None

    try:

        connection = get_db_connection()
        cursor = connection.cursor()

        cursor.execute(
            """
            INSERT INTO images (
                image_id,
                owner_id,
                filename,
                status,
                created_at
            )
            VALUES (%s, %s, %s, %s, %s)
            """,
            (
                image_id,
                user_id,
                filename,
                "PENDING",
                timestamp,
            ),
        )

        connection.commit()

        logger.info("Created image %s for user %s", image_id, user_id)

    except Exception:

        logger.exception("Failed to create image metadata")

        if connection:
            connection.rollback()

        return response(
            500,
            {"message": "Failed to create image."},
        )

    finally:

        if cursor:
            cursor.close()

        if connection:
            connection.close()

    upload_url = s3.generate_presigned_url(
        "put_object",
        Params={
            "Bucket": UPLOAD_BUCKET,
            "Key": f"uploads/{user_id}/{image_id}/{filename}",
            "ContentType": content_type,
        },
        ExpiresIn=900,
    )

    return response(
        201,
        {
            "imageId": image_id,
            "uploadUrl": upload_url,
        },
    )


def list_images(event):

    user_id = get_user_id(event)

    connection = None
    cursor = None

    try:

        connection = get_db_connection()

        cursor = connection.cursor()

        cursor.execute(
            """
            SELECT
                image_id,
                filename,
                status,
                created_at
            FROM images
            WHERE owner_id = %s
            ORDER BY created_at DESC
            """,
            (user_id,),
        )

        rows = cursor.fetchall()

        images = []

        for row in rows:

            images.append(
                {
                    "imageId": str(row[0]),
                    "filename": row[1],
                    "status": row[2],
                    "createdAt": row[3].isoformat(),
                }
            )

    except Exception:

        logger.exception("Failed to retrieve images.")

        return response(
            500,
            {"message": "Failed to retrieve images."},
        )

    finally:

        if cursor:
            cursor.close()

        if connection:
            connection.close()

    return response(
        200,
        {"images": images},
    )


def get_image(event):

    user_id = get_user_id(event)

    path_params = event.get("pathParameters") or {}

    image_id = path_params.get("imageId")

    if not image_id:
        return response(
            400,
            {"message": "Image ID required"},
        )

    cache_key = f"image:{image_id}"

    redis_client = get_redis_client()

    item = None

    try:

        cached = redis_client.get(cache_key)

        if cached:

            logger.info("Redis cache hit: %s", cache_key)

            item = json.loads(cached)

        else:

            logger.info("Redis cache miss: %s", cache_key)

    except Exception:

        logger.exception("Redis lookup failed. Falling back to PostgreSQL.")

    if item is None:

        connection = None
        cursor = None

        try:

            connection = get_db_connection()

            cursor = connection.cursor()

            cursor.execute(
                """
                SELECT *
                FROM images
                WHERE image_id = %s
                AND owner_id = %s;
                """,
                (
                    image_id,
                    user_id,
                ),
            )

            row = cursor.fetchone()

            if row is None:
                return response(
                    404,
                    {"message": "Image not found"},
                )

            item = {
                "imageId": str(row[0]),
                "ownerId": str(row[1]),
                "filename": row[2],
                "status": row[3],
                "createdAt": row[4].isoformat(),
                "processedAt": row[5].isoformat() if row[5] else None,
                "fileSize": row[6],
                "contentType": row[7],
                "extension": row[8],
            }

        except Exception:

            logger.exception("Failed to retrieve image.")

            return response(
                500,
                {"message": "Failed to retrieve image."},
            )

        finally:

            if cursor:
                cursor.close()

            if connection:
                connection.close()

        try:

            redis_client.setex(
                cache_key,
                300,
                json.dumps(item),
            )

            logger.info("Cached image metadata: %s", cache_key)

        except Exception:

            logger.exception("Failed to update Redis cache.")

    filename = item.get("filename")

    if not filename:

        return response(
            500,
            {"message": "Image record is missing filename"},
        )

    download_url = s3.generate_presigned_url(
        "get_object",
        Params={
            "Bucket": UPLOAD_BUCKET,
            "Key": f"uploads/{user_id}/{image_id}/{filename}",
        },
        ExpiresIn=3600,
    )

    return response(
        200,
        {
            "image": item,
            "downloadUrl": download_url,
        },
    )
