import boto3, os, time
import concurrent.futures
from botocore.exceptions import ClientError
from tqdm import tqdm

# global init
failed_to_delete = []

# Setup AWS session
def setup_session():
    if 'AWS_ACCESS_KEY_ID' in os.environ and 'AWS_SECRET_ACCESS_KEY' in os.environ:
        aws_access_key_id = os.getenv('AWS_ACCESS_KEY_ID')
        aws_secret_access_key = os.getenv('AWS_SECRET_ACCESS_KEY')
        print("Logged in using environmental AWS credentials")
        return boto3.Session(aws_access_key_id=aws_access_key_id, aws_secret_access_key=aws_secret_access_key)
    else:
        profile = input("Enter AWS profile name (↲ for default): ") or 'default'
        return boto3.Session(profile_name=profile)

# Delete all objects in the bucket
def delete_all_objects(bucket_name):
    s3 = session.client('s3')
    objects_to_delete = s3.list_object_versions(Bucket=bucket_name)

    if 'Versions' in objects_to_delete:
        with tqdm(total=len(objects_to_delete['Versions']), desc=f"Deleting objects in {bucket_name}", ncols=80, bar_format='{l_bar}{bar}| {n_fmt}/{total_fmt}') as pbar:
            while 'Versions' in objects_to_delete:
                delete_dict = {
                    'Objects': [{'Key': key['Key'], 'VersionId': key['VersionId']} for key in objects_to_delete['Versions']]
                }
                s3.delete_objects(Bucket=bucket_name, Delete=delete_dict)
                pbar.update(len(delete_dict['Objects']))
                objects_to_delete = s3.list_object_versions(Bucket=bucket_name)

        # Add code to delete incomplete multipart uploads
        multipart_uploads = s3.list_multipart_uploads(Bucket=bucket_name)
        for upload in multipart_uploads.get('Uploads', []):
            s3.abort_multipart_upload(Bucket=bucket_name, Key=upload['Key'], UploadId=upload['UploadId'])
    else:
        print(f"No versions found in bucket {bucket_name}")

# Get list of buckets to delete
def get_buckets_to_delete(keywords: list, exception_keywords: list) -> list:
    s3 = session.client('s3')
    buckets_to_delete = []
    for bucket in s3.list_buckets()['Buckets']:
        if any(keyword in bucket['Name'] for keyword in keywords) and not any(keyword in bucket['Name'] for keyword in exception_keywords):
            print(f'Keyword matches: {bucket["Name"]}')
            buckets_to_delete.append(bucket['Name'])
    return buckets_to_delete

# Delete a bucket
def delete_bucket(bucket_name):
    s3 = session.client('s3')

    try:
        delete_all_objects(bucket_name)
        s3.delete_bucket(Bucket=bucket_name)
    except ClientError as e:
        if e.response['Error']['Code'] == 'BucketNotEmpty':
            print(f"Bucket {bucket_name} is not empty.")
            failed_to_delete.append(bucket_name)
        else:
            print("An unexpected error occurred:", e)
            failed_to_delete.append(bucket_name)

# Main function
if __name__ == "__main__":
    session = setup_session()
    region = input("Enter AWS region (↲ for us-east-2): ") or 'us-east-2'
    keywords = [keyword.strip() for keyword in input("Enter the keywords, separated by commas: ").split(',')]
    exception_keywords = [keyword.strip() for keyword in input("Enter the exception keywords, separated by commas: ").split(',')]

    buckets_to_delete = get_buckets_to_delete(keywords, exception_keywords)
    print(f'Found {len(buckets_to_delete)} buckets to delete.')
    confirm = input("Do you want to delete the S3 buckets above? (y/n) ")

    if confirm.lower() == 'y':
        with tqdm(total=len(buckets_to_delete), desc="Deleting buckets", ncols=80, bar_format='{l_bar}{bar}| {n_fmt}/{total_fmt}') as pbar:
            with concurrent.futures.ThreadPoolExecutor() as executor:
                for _ in executor.map(delete_bucket, buckets_to_delete):
                    pbar.update()

        if len(failed_to_delete) > 0:
            print("The following buckets failed to delete:")
            for bucket in failed_to_delete:
                print(bucket)
        else:
            print("All buckets were deleted successfully.")
    else:
        print("Skipped - No buckets have been impacted.")

