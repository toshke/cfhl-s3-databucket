CloudFormation do
  name = external_parameters.fetch(:name, nil)
  default_encryption = external_parameters.fetch(:default_encryption, nil)
  kms_bucket_key_enabled = external_parameters.fetch(:kms_bucket_key_enabled, true)
  create_kms_key = external_parameters.fetch(:create_kms_key, false)
  data_classification = external_parameters.fetch(:data_classification, 'internal')
  
  tags = [{ Key: "data-classification", Value: data_classification }]
  if default_encryption == "aws:kms" && create_kms_key
    key_policy = {
      Version: "2012-10-17",
      Statement: [{
        Sid: :KeyAdmin,
        Effect: :Allow,
        Resource: "*",
        Action: "kms:*",
        Principal: FnSub("arn:aws:iam::${AWS::AccountId}:root"),
      }],
    }
    KMS_Key(:BucketEncryptionKey) do
      Description "KMS Key to encrypt bucket #{name}"
      Enabled true
      EnableKeyRotation true
      KeyPolicy key_policy
      KeySpec "SYMMETRIC_DEFAULT"
      KeyUsage "ENCRYPT_DECRYPT"
      Tags tags
    end
  end

  S3_Bucket(:bucket) do
    BucketName name if name
    if default_encryption
      enc = {
        ServerSideEncryptionConfiguration: [{
          ServerSideEncryptionByDefault: {
            SSEAlgorithm: default_encryption,
          },
        }],
      }
      if default_encryption == "aws:kms"
        enc[:ServerSideEncryptionConfiguration][0][:ServerSideEncryptionByDefault][:KMSMasterKeyID] = default_kms_key_id unless create_kms_key
        enc[:ServerSideEncryptionConfiguration][0][:ServerSideEncryptionByDefault][:KMSMasterKeyID] = Ref(:BucketEncryptionKey) if create_kms_key
        enc[:ServerSideEncryptionConfiguration][0][:BucketKeyEnabled] = kms_bucket_key_enabled
      end
      BucketEncryption enc
    end
  end

  policy_statements = []

  policy = {
    Version: "2012-10-17",
    Statement: policy_statements,
  }

  S3_BucketPolicy(:policy) do
    Bucket Ref(:bucket)
    PolicyDocument(policy)
  end
end
