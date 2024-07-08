import json
import logging
import boto3
from decimal import Decimal
from botocore.exceptions import ClientError

logger = logging.getLogger()
logger.setLevel(logging.INFO)

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('TravelDestinations')

def handler(event, context):
    logger.info('API event: {}'.format(event))
    
    try:
        http_method = event['httpMethod']
        if http_method == 'GET':
            response = get_all_destinations()
        elif http_method == 'POST':
            item = json.loads(event['body'])
            response = post_destination(item)
        
    except ClientError as e:
        logger.error('Error: {}'.format(e))
        response = generate_response(404, e.response['Error']['Message'])
        
    return response



def get_all_destinations():
    try:
        scan_params = {
            'TableName': table.name
        }
        items = recursive_scan(scan_params, [])
        logger.info('GET ALL items: {}'.format(items))
        return generate_response(200, items)
    except ClientError as e:
        logger.error('Error: {}'.format(e))
        return generate_response(404, e.response['Error']['Message'])
    
def recursive_scan(scan_params, items):
    response = table.scan(**scan_params)
    items += response['Items']
    if 'LastEvaluatedKey' in response:
        scan_params['ExclusiveStartKey'] = response['LastEvaluatedKey']
        recursive_scan(scan_params, items)
    return items

def post_destination(item):
    try:
        response = table.put_item(Item=item)
        logger.info('POST response: {}'.format(response))
        body = {
            'message': 'Item added successfully',
            'item': item
        }
        return generate_response(200, body)
    except ClientError as e:
        logger.error('Error: {}'.format(e))
        return generate_response(404, e.response['Error']['Message'])

def generate_response(status_code, body):
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
        },
        'body': json.dumps(body)
    }