import logging
import os

import pg8000

logger = logging.getLogger()
logger.setLevel(logging.INFO)

DB_HOST = os.environ["DB_HOST"]
DB_PORT = int(os.environ.get("DB_PORT", "5432"))
DB_NAME = os.environ["DB_NAME"]
DB_USER = os.environ["DB_USER"]
DB_PASSWORD = os.environ["DB_PASSWORD"]


def lambda_handler(event, context):
    logger.info("Starting database migration.")

    connection = None
    cursor = None

    try:
        connection = pg8000.connect(
            host=DB_HOST,
            port=DB_PORT,
            database=DB_NAME,
            user=DB_USER,
            password=DB_PASSWORD,
        )

        cursor = connection.cursor()

        schema_path = os.path.join(os.path.dirname(__file__), "schema.sql")

        logger.info("Executing schema.sql")

        with open(schema_path, "r", encoding="utf-8") as file:
            schema_sql = file.read()

        cursor.execute(schema_sql)

        connection.commit()

        logger.info("Database migration completed successfully.")

        return {"statusCode": 200, "body": "Database initialized successfully."}

    except Exception as e:
        logger.exception("Database migration failed.")

        if connection is not None:
            connection.rollback()

        return {"statusCode": 500, "body": f"Database migration failed: {str(e)}"}

    finally:
        if cursor is not None:
            cursor.close()

        if connection is not None:
            connection.close()

        logger.info("Database connection closed.")
