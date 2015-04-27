#!/bin/sh
#
#	AWS EC2 AutoSnapShotRotation.sh
#
#	@author     magnum
#

#       EC2インスタンスID
ec2InstanceId="xxxxxx";

#       スナップショット世代数
ec2SnapshotGenerationNumber=2;

volumes=$(aws ec2 describe-volumes --query "Volumes[*].VolumeId" --output text);
volumeIds=$(aws ec2 describe-instances --filters "Name=instance-id,Values=${ec2InstanceId}" --query "Reservations[*].Instances[*].BlockDeviceMappings[*].Ebs.VolumeId" --output text);

for volumeId in $volumes; do
        for snapshotVolumeId in $volumeIds; do
                if [ $volumeId = $snapshotVolumeId ]; then
                        aws ec2 create-snapshot --volume-id $volumeId --description "${ec2InstanceId}/${volumeId} snapshot, Created by $(date)"
                        snapshots=$(aws ec2 describe-snapshots --filters "Name=volume-id,Values=${volumeId}" --query "Snapshots[*].[SnapshotId,StartTime]" --output text  | sort -k2 -r | awk '{print $1}');
                        snapshotNumber=0;
                        for snapshotsId in $snapshots; do
                                if [ $snapshotNumber -ge $ec2SnapshotGenerationNumber ]; then
                                        aws ec2 delete-snapshot --snapshot-id "${snapshotsId}";
                                fi
                                snapshotNumber=`expr $snapshotNumber + 1`;
                        done;
                fi;
        done;
done;