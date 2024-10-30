import boto3

print(" --------------------------------------------------------------------------------")

print("  _____   _____    _____  _                                 ");
print(" / ____| / ____|  / ____|| |                                ");
print("| (___  | |  __  | |     | |  ___   __ _  _ __    ___  _ __ ");
print(" \___ \ | | |_ | | |     | | / _ \ / _` || '_ \  / _ \| '__|");
print(" ____) || |__| | | |____ | ||  __/| (_| || | | ||  __/| |   ");
print("|_____/  \_____|  \_____||_| \___| \__,_||_| |_| \___||_|   ");

print(" \n--- Unused Security Groups Cleaner")

print("\n Author: Satish Patnayak (@satish_patnayak)\n")

print(" --------------------------------------------------------------------------------")
#Provide the aws profile name configure when it prompts 
profile_name = input("Enter AWS profile name: ")

print(f"\n [Info] -  Scanning for unused Security groups using profile - {profile_name}");
#Update the list based on your requirement
regions = [
    'us-east-1', 'us-east-2', 'us-west-1', 'us-west-2'
]
'''regions = [
    'us-east-1', 'us-east-2', 'us-west-1', 'us-west-2',
    'af-south-1', 'ap-east-1', 'ap-south-1', 'ap-northeast-2', 'ap-southeast-1', 'ap-southeast-2',
    'ap-northeast-1', 'ca-central-1', 'eu-central-1', 'eu-west-1', 'eu-west-2', 'eu-south-1', 'eu-west-3',
    'eu-north-1', 'me-south-1', 'sa-east-1'
]'''

# List of security group IDs to exclude from deletion
exception_list = []

for region in regions:
    print("  --------------------------------------------------------------------------------");
    print(f"| Region: {region}                                                               |");
    print("  --------------------------------------------------------------------------------");
    session = boto3.Session(profile_name=profile_name, region_name=region)
    ec2 = session.client('ec2')

    response = ec2.describe_security_groups()
    unused_security_groups = []

    for group in response['SecurityGroups']:
        group_id = group['GroupId']
        group_name = group['GroupName']

        if group_name == 'default':
            continue  # Skip the default security group

        response = ec2.describe_network_interfaces(Filters=[{'Name': 'group-id', 'Values': [group_id]}])
        if not response['NetworkInterfaces']:
            unused_security_groups.append(group_id)

    for group_id in unused_security_groups:
        if group_id in exception_list:
            print(f"[Info] - Skipping security group {group_id} (in exception list)")
            continue
        print(f"[Info] - Found unused Security Group {group_id}")
        try:
            ec2.delete_security_group(GroupId=group_id)
            print(f"[Info] - Deleted Unused Security Group {group_id}")
        except Exception as e:
            print(f"Error: {e}")
