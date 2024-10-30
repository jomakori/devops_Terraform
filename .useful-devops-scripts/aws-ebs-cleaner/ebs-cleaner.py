import boto3

# Setup AWS session
profile = input("Enter AWS profile name (↲ for default): ") or 'default'
region = input("Enter AWS region (↲ for us-east-2): ") or 'us-east-2'
session = boto3.Session(profile_name=profile, region_name=region)
ec2 = session.resource('ec2')
volumes = ec2.volumes.all()

# Terminate un-attached EBS volumes
to_terminate=[]
for volume in volumes:
    print('Evaluating volume {0}'.format(volume.id))
    print('The number of attachments for this volume is {0}'.format(len(volume.attachments)))

    # Here's where you might add other business logic for deletion criteria
    if len(volume.attachments) == 0:
        to_terminate.append(volume)

if len(to_terminate) == 0:
    print ("No volumes to terminate! Exiting.")
    exit()

for volume in to_terminate:
    print('Deleting volume {0}'.format(volume.id))
    volume.delete()
