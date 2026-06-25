import os
import psycopg2

DB_HOST = os.environ["DB_HOST"]
DB_NAME = os.environ["DB_NAME"]
DB_USER = os.environ["DB_USER"]
DB_PASSWORD = os.environ["DB_PASSWORD"]


def lambda_handler(event, context):

    connection = psycopg2.connect(
        host=DB_HOST,
        database=DB_NAME,
        user=DB_USER,
        password=DB_PASSWORD,
    )

    try:

        cursor = connection.cursor()

        schema_path = os.path.join(os.path.dirname(__file__), "schema.sql")

        with open(schema_path, "r") as file:
            cursor.execute(file.read())

        connection.commit()

        cursor.close()

        return {"statusCode": 200, "body": "Database initialized successfully."}

    finally:

        connection.close()
