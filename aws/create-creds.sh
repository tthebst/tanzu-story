#!/bin/bash
export AWS_ACCESS_KEY_ID=$1
export AWS_SECRET_ACCESS_KEY=$2
export AWS_REGION=$3


# get number of keys saved in cluster api aws iam
num_keys="$(aws iam list-access-keys --user-name bootstrapper.cluster-api-provider-aws.sigs.k8s.io | jq '.AccessKeyMetadata | length')"

# if two keys are present delete one key because maximum allowed keys is 2
if [[ $num_keys -eq 2 ]]; then
    echo "two keys in iam account will delete one"
    key_id="$(aws iam list-access-keys --user-name bootstrapper.cluster-api-provider-aws.sigs.k8s.io | jq --raw-output '.AccessKeyMetadata[0].AccessKeyId')"
    aws iam delete-access-key --user-name bootstrapper.cluster-api-provider-aws.sigs.k8s.io --access-key-id $key_id
    echo "deleted key with id:" $key_id

    echo "creating new key"
    AWS_CREDENTIALS="$(aws iam create-access-key --user-name bootstrapper.cluster-api-provider-aws.sigs.k8s.io --output json)"
    echo "created new key"

    echo export AWS_CREDENTIALS=\'$AWS_CREDENTIALS\' >>$HOME/.bashrc
    echo export AWS_ACCESS_KEY_ID=$(echo $AWS_CREDENTIALS | jq .AccessKey.AccessKeyId -r) >>$HOME/.bashrc
    echo export AWS_SECRET_ACCESS_KEY=$(echo $AWS_CREDENTIALS | jq .AccessKey.SecretAccessKey -r) >>$HOME/.bashrc
    echo export AWS_B64ENCODED_CREDENTIALS=$(clusterawsadm alpha bootstrap encode-aws-credentials) >>$HOME/.bashrc
    echo "exported new key to bashrc"
else
    echo "creating new key"
    AWS_CREDENTIALS="$(aws iam create-access-key --user-name bootstrapper.cluster-api-provider-aws.sigs.k8s.io --output json)"
    echo "created new key"

    echo export AWS_CREDENTIALS=\'$AWS_CREDENTIALS\' >>$HOME/.bashrc
    echo export AWS_ACCESS_KEY_ID=$(echo $AWS_CREDENTIALS | jq .AccessKey.AccessKeyId -r) >>$HOME/.bashrc
    echo export AWS_SECRET_ACCESS_KEY=$(echo $AWS_CREDENTIALS | jq .AccessKey.SecretAccessKey -r) >>$HOME/.bashrc
    echo export AWS_B64ENCODED_CREDENTIALS=$(clusterawsadm alpha bootstrap encode-aws-credentials) >>$HOME/.bashrc
    echo "exported new key to bashrc"
fi
