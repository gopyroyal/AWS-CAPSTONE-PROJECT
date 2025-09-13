#!/usr/bin/env bash
set -euo pipefail

REGION="ca-central-1"
BUCKET_NAME="gopi-capstone-terraform-state"
LOCK_TABLE="gopi-capstone-terraform-lock"
PROJECT_PREFIX="gopi-capstone"

echo "Detecting AWS Account ID..."
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "Account: $ACCOUNT_ID"

echo "Creating S3 bucket $BUCKET_NAME (if not exists)..."
if ! aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
  aws s3api create-bucket --bucket "$BUCKET_NAME" --region "$REGION" --create-bucket-configuration LocationConstraint="$REGION"
else
  echo "Bucket already exists."
fi
aws s3api put-bucket-versioning --bucket "$BUCKET_NAME" --versioning-configuration Status=Enabled
aws s3api put-bucket-encryption --bucket "$BUCKET_NAME" --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'

echo "Creating DynamoDB table $LOCK_TABLE (if not exists)..."
if ! aws dynamodb describe-table --table-name "$LOCK_TABLE" >/dev/null 2>&1; then
  aws dynamodb create-table         --table-name "$LOCK_TABLE"         --attribute-definitions AttributeName=LockID,AttributeType=S         --key-schema AttributeName=LockID,KeyType=HASH         --billing-mode PAY_PER_REQUEST         --region "$REGION"
  echo "Waiting for DynamoDB table to be ACTIVE..."
  aws dynamodb wait table-exists --table-name "$LOCK_TABLE"
else
  echo "DynamoDB table already exists."
fi

echo "Setting up GitHub OIDC provider (if not exists)..."
if ! aws iam list-open-id-connect-providers --query 'OpenIDConnectProviderList[].Arn' | grep -q 'token.actions.githubusercontent.com'; then
  aws iam create-open-id-connect-provider         --url https://token.actions.githubusercontent.com         --client-id-list "sts.amazonaws.com"         --thumbprint-list "6938fd4d98bab03faadb97b34396831e3780aea1"
else
  echo "OIDC provider already configured."
fi

ROLE_NAME="${PROJECT_PREFIX}-github-oidc-role"
POLICY_NAME="${PROJECT_PREFIX}-terraform-admin"

echo "Creating/Updating IAM role $ROLE_NAME for GitHub OIDC..."
TRUST_POLICY=$(cat <<'JSON'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": { "Federated": "arn:aws:iam::ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com" },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": [
            "repo:${GH_OWNER}/${GH_REPO}:ref:refs/heads/*",
            "repo:${GH_OWNER}/${GH_REPO}:pull_request"
          ]
        }
      }
    }
  ]
}
JSON
)
TRUST_POLICY=${TRUST_POLICY/ACCOUNT_ID/$ACCOUNT_ID}

if ! aws iam get-role --role-name "$ROLE_NAME" >/dev/null 2>&1; then
  aws iam create-role --role-name "$ROLE_NAME" --assume-role-policy-document "$TRUST_POLICY"
else
  aws iam update-assume-role-policy --role-name "$ROLE_NAME" --policy-document "$TRUST_POLICY"
fi

echo "Attaching AdministratorAccess policy to $ROLE_NAME (for capstone simplicity)."
if ! aws iam list-attached-role-policies --role-name "$ROLE_NAME" --query 'AttachedPolicies[].PolicyArn' | grep -q 'AdministratorAccess'; then
  aws iam attach-role-policy --role-name "$ROLE_NAME" --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
fi

echo "Bootstrap complete."
echo ""
echo "Next steps:"
echo "1) In GitHub repo settings -> Secrets and variables -> Actions, add:"
echo "   - AWS_ROLE_ARN = arn:aws:iam::$ACCOUNT_ID:role/$ROLE_NAME"
echo "2) Push this repo to GitHub (branch: main)."
echo "3) The workflow will run plan/apply for dev, staging, prod."
