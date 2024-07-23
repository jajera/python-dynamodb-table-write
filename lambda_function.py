import json
import os
import logging
import boto3
from botocore.exceptions import ClientError
from typing import Any

logging.basicConfig(level=logging.INFO)

region = os.getenv('AWS_REGION')
table_name = os.getenv('TABLE_NAME')

if not table_name:
    logging.fatal("TABLE_NAME environment variable is required")
    raise ValueError("TABLE_NAME environment variable is required")

if not region:
    logging.fatal("AWS_REGION environment variable is required")
    raise ValueError("AWS_REGION environment variable is required")

try:
    table_item = json.loads(os.getenv('TABLE_ITEM', '{}'))
    if not table_item:
        raise ValueError
except (json.JSONDecodeError, ValueError):
    logging.fatal(
        "TABLE_ITEM environment variable is required and should be a valid JSON string")
    raise ValueError(
        "TABLE_ITEM environment variable is required and should be a valid JSON string")

dynamodb = boto3.resource('dynamodb', region_name=region)
table = dynamodb.Table(table_name)

def write_dynamodb_table_item(data: dict) -> None:
    try:
        response = table.put_item(
            Item=data,
            ConditionExpression="attribute_not_exists(#s) AND attribute_not_exists(#t) OR #r <> :r",
            ExpressionAttributeNames={
                '#s': 'source',
                '#t': 'timestamp',
                '#r': 'region'
            },
            ExpressionAttributeValues={':r': data['region']}
        )
        logging.info("Data written to DynamoDB: %s", response)
    except ClientError as e:
        if e.response['Error']['Code'] == 'ConditionalCheckFailedException':
            logging.info("Item exists, skipping write.")
        else:
            logging.error("Failed to write to DynamoDB: %s", e.response['Error']['Message'])
    except Exception as e:
        logging.error("Unexpected error: %s", str(e))

def lambda_handler(event: dict, context: Any) -> dict:
    try:
        write_dynamodb_table_item(table_item)
        return {
            'statusCode': 200,
            'body': 'Message processed successfully'
        }
    except Exception as e:
        logging.error("Lambda function error: %s", e)
        return {
            'statusCode': 500,
            'body': f'Error: {str(e)}'
        }

if __name__ == '__main__':
    write_dynamodb_table_item(table_item)
