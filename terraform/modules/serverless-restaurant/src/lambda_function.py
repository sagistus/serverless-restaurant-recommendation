from datetime import datetime
import os
import json
import logging
import boto3
import psycopg2

logger = logging.getLogger()
logger.setLevel(logging.INFO)

STYLES_ENV = os.getenv('RESTAURANT_STYLES', '').split(',')
VEGETARIAN_ENV = os.getenv('VEGETARIAN_KEYWORDS', '').split(',')
DELIVERY_ENV = os.getenv('DELIVERY_KEYWORDS', '').split(',')
SECRETS_MANAGER_ARN = os.getenv('DB_SECRET_ARN')
QUERY =  """
    SELECT name, style, address, vegetarian, open_hour, close_hour, delivery
    FROM restaurants
    WHERE
        (%s IS NULL OR style = ANY (%s))
        AND (%s IS NULL OR vegetarian = %s)
        AND (%s IS NULL OR delivery = %s)
        AND (
            (open_hour <= %s AND close_hour > %s) 
            OR
            (open_hour >= %s AND close_hour <= %s)
        )
"""

def get_db_connection_details():
    secretsmanager_client = boto3.client('secretsmanager')
    response = secretsmanager_client.get_secret_value(SecretId=SECRETS_MANAGER_ARN)
    secret = json.loads(response['SecretString'])
    return secret

secret = get_db_connection_details()
conn = psycopg2.connect(
        host=secret['host'],
        port=secret['port'],
        database=secret['dbname'],
        user=secret['username'],
        password=secret['password']
    )

def lambda_handler(event, context):
    try:
        logger.info(f'Received event: {event}')
        mapped_query = map_query_to_obj(event.get('body').lower())
        matching_restaurants = mapped_query.get_data_from_db()

        logger.info(f'Found {len(matching_restaurants)} matching restaurant(s).')

        return {
            'statusCode': 200,
            'body': json.dumps({
                'matches': matching_restaurants
            })
        }

    except Exception as e:
        logger.exception('Unexpected error occurred.')
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }

def map_query_to_obj(event):
    matched_styles = [style for style in STYLES_ENV if style.lower() in event]
    vegetarian = any(word in event for word in VEGETARIAN_ENV)
    delivery = any(word in event for word in DELIVERY_ENV)

    return RestaurantQuery(
        matched_styles=matched_styles,
        vegetarian=vegetarian,
        delivery=delivery
    )

class RestaurantQuery:
    def __init__(self, matched_styles, vegetarian, delivery):
        self.matched_styles = matched_styles
        self.vegetarian = vegetarian
        self.delivery = delivery
        self.filtered_restaurant = []

    def get_data_from_db(self):
        if conn is None:
            raise Exception('No database connection available.')

        now = datetime.now().time()
        query = QUERY
        values = [
            self.matched_styles if self.matched_styles else None,
            self.vegetarian,
            self.delivery,
            now,
            now
        ]

        with conn.cursor() as cur:
            cur.execute(query, values)
            rows = cur.fetchall()

            for row in rows:
                restaurant = {
                    'name': row[0],
                    'style': row[1],
                    'address': row[2],
                    'vegetarian': row[3],
                    'openHour': str(row[4]),
                    'closeHour': str(row[5]),
                    'delivery': row[6]
                }
                self.filtered_restaurant.append(restaurant)
