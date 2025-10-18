# Backend Strategy for Multi-Domain Support

## Overview
This document outlines the backend and infrastructure changes required to support multiple domains (kingslanding.io and boxshop.io) with user-specific domain permissions.

## Current Architecture
- Single domain: kingslanding.io
- S3 bucket for storage
- CloudFront distribution for CDN
- Lambda functions for upload and invalidation
- API Gateway with Cognito authentication
- No user-domain permission mapping

## Required Changes

### 1. Lambda Function Updates

#### S3 Upload Lambda (`lambdas/s3_upload.py`)
**Changes needed:**
- Accept `domain` parameter from request body
- Accept `X-Target-Domain` header from request
- Validate that the user has permission to upload to the selected domain
- Determine target S3 bucket or path based on domain
- Update S3 key to include domain-specific paths (e.g., `kingslanding/pages/` vs `boxshop/pages/`)

**Implementation approach:**
```python
def lambda_handler(event, context):
    # Extract domain from request
    domain = json.loads(event['body']).get('domain')
    
    # Validate user has permission for this domain
    user_id = get_user_from_token(event['headers']['Authorization'])
    if not user_has_domain_access(user_id, domain):
        return {
            'statusCode': 403,
            'body': json.dumps({'error': 'Access denied for this domain'})
        }
    
    # Upload to domain-specific path
    s3_key = f"{domain}/pages/{filename}"
    # ... rest of upload logic
```

### 2. DynamoDB for User Permissions

#### Schema Design
**Table: `user_domain_permissions`**
- **Partition Key:** `user_id` (String) - Cognito user ID
- **Attributes:**
  - `email` (String) - User email for reference
  - `allowed_domains` (List) - Array of domain strings user can access
  - `created_at` (String) - ISO timestamp
  - `updated_at` (String) - ISO timestamp

**Example items:**
```json
{
  "user_id": "user-123",
  "email": "tony@example.com",
  "allowed_domains": ["kingslanding.io"],
  "created_at": "2024-01-01T00:00:00Z",
  "updated_at": "2024-01-01T00:00:00Z"
}

{
  "user_id": "user-456",
  "email": "jeff@example.com",
  "allowed_domains": ["kingslanding.io", "boxshop.io"],
  "created_at": "2024-01-01T00:00:00Z",
  "updated_at": "2024-01-01T00:00:00Z"
}
```

### 3. API Gateway Updates

#### New Endpoints
- `GET /domains` - Return list of domains the authenticated user can access
  - Response: `{"domains": ["kingslanding.io", "boxshop.io"]}`
  - Used by UI to populate dropdown dynamically

#### Existing Endpoint Updates
- `PUT /` (upload) - Add validation for domain parameter
  - Requires new custom authorizer or Lambda integration to check DynamoDB

### 4. S3 Bucket Structure

#### Option A: Single Bucket with Domain Prefixes (Recommended)
```
s3://kingslanding-content/
├── kingslanding.io/
│   ├── pages/
│   │   ├── index.html
│   │   └── about.html
│   └── index.html (webapp)
└── boxshop.io/
    ├── pages/
    │   ├── index.html
    │   └── products.html
    └── index.html (webapp)
```

**Pros:**
- Simpler infrastructure
- Single CloudFront distribution with multiple origins
- Easier to manage

**Cons:**
- Need to configure S3 event notifications carefully
- More complex IAM policies

#### Option B: Separate Buckets per Domain
```
s3://kingslanding-content/
s3://boxshop-content/
```

**Pros:**
- Clear separation of concerns
- Easier permissions management
- Independent scaling

**Cons:**
- More infrastructure to manage
- Duplicate Lambda functions or more complex logic

### 5. CloudFront Updates

#### Option A: Single Distribution with Behaviors
- Add origin for each domain
- Configure behaviors to route based on Host header
- Example:
  - Host: kingslanding.io → Origin: S3 bucket at `/kingslanding.io/`
  - Host: boxshop.io → Origin: S3 bucket at `/boxshop.io/`

#### Option B: Separate Distributions
- One CloudFront distribution per domain
- Simpler configuration but more infrastructure

**Recommendation:** Option A (single distribution) for cost efficiency

### 6. Cognito Updates

#### Custom Attributes
Add custom attribute to Cognito user pool:
- `custom:allowed_domains` (String) - Comma-separated list of allowed domains

**Alternative:** Keep permissions in DynamoDB for flexibility

### 7. CloudFront Invalidation Lambda

Update `lambdas/invalidation.py`:
- Parse S3 key to determine domain
- Create invalidation for correct CloudFront distribution (if using Option B)
- Update path patterns to include domain prefix (if using Option A)

**Implementation:**
```python
def lambda_handler(event, context):
    # Extract S3 key from event
    s3_key = event['Records'][0]['s3']['object']['key']
    
    # Parse domain from key (e.g., "kingslanding.io/pages/index.html")
    domain = s3_key.split('/')[0]
    
    # Determine invalidation path
    # For kingslanding.io/pages/index.html, invalidate /pages/index.html on kingslanding.io
    path = '/' + '/'.join(s3_key.split('/')[1:])
    
    # Create invalidation with correct distribution
    cloudfront.create_invalidation(
        DistributionId=get_distribution_for_domain(domain),
        InvalidationBatch={...}
    )
```

### 8. Terraform Infrastructure Changes

#### Required Updates:
1. **DynamoDB Table** (`terraform/dynamodb.tf` - new file)
   ```hcl
   resource "aws_dynamodb_table" "user_domain_permissions" {
     name           = "kingslanding-user-domain-permissions"
     billing_mode   = "PAY_PER_REQUEST"
     hash_key       = "user_id"
     
     attribute {
       name = "user_id"
       type = "S"
     }
   }
   ```

2. **S3 Bucket Structure** (update `terraform/s3.tf`)
   - Configure prefixes for each domain
   - Update bucket policies for new structure

3. **Lambda IAM Roles** (update `terraform/iam.tf`)
   - Add DynamoDB read permissions for S3 upload lambda
   - Add permissions to query user permissions

4. **CloudFront** (update `terraform/cloudfront.tf`)
   - Add multiple origins or behaviors as needed
   - Configure proper cache behaviors per domain

5. **API Gateway** (update `terraform/api_gateway.tf`)
   - Add new `/domains` endpoint
   - Update CORS for new headers

### 9. Migration Strategy

#### Phase 1: UI Changes (Current)
- ✅ Add domain dropdown to UI
- ✅ Update frontend to send domain in upload request

#### Phase 2: Backend Preparation
1. Create DynamoDB table
2. Populate initial user permissions (all users → kingslanding.io only)
3. Update Lambda functions with domain validation (read-only mode)

#### Phase 3: S3 Restructuring
1. Create new S3 structure with domain prefixes
2. Copy existing content to `kingslanding.io/` prefix
3. Update CloudFront origins/behaviors
4. Test thoroughly

#### Phase 4: Enable Multi-Domain
1. Enable domain validation in Lambda
2. Add boxshop.io to select users' permissions
3. Monitor and validate

#### Phase 5: Add Domain Discovery API
1. Implement `GET /domains` endpoint
2. Update UI to dynamically load domains from API
3. Remove hardcoded domain list from frontend

## Cost Implications

### New Resources:
- **DynamoDB:** ~$0.25/month for 1GB storage + minimal reads (PAY_PER_REQUEST)
- **Additional S3 storage:** No change (same total storage)
- **CloudFront:** Minimal change (same distribution, different paths)
- **Lambda executions:** +~100-200 invocations/month for permission checks (~$0)

**Total estimated additional cost:** ~$0.25-1.00/month

## Security Considerations

1. **Authorization:** Always validate user permissions server-side, never trust client
2. **Domain validation:** Whitelist allowed domains in Lambda to prevent injection
3. **S3 bucket policies:** Ensure proper isolation between domain content
4. **API rate limiting:** Implement rate limiting on new `/domains` endpoint
5. **Audit logging:** Log all domain permission checks and changes

## Testing Strategy

1. **Unit tests:** Test Lambda functions with various domain inputs
2. **Integration tests:** Test full upload flow for both domains
3. **Permission tests:** Verify users can only access allowed domains
4. **UI tests:** Validate dropdown shows correct domains per user
5. **Load tests:** Ensure DynamoDB can handle permission lookups at scale

## Future Enhancements

1. **Admin UI:** Build interface to manage user-domain permissions
2. **Domain groups:** Allow grouping domains for easier permission management
3. **Audit trail:** Track all uploads by user and domain
4. **Usage analytics:** Track uploads per domain for insights
5. **Custom domains:** Support arbitrary custom domains beyond kingslanding.io and boxshop.io

## Rollback Plan

If issues arise:
1. Update UI to hide domain dropdown (revert to kingslanding.io only)
2. Remove domain validation from Lambda (allow all uploads to kingslanding.io path)
3. Keep DynamoDB table for when ready to retry
4. Document lessons learned and adjust strategy

## Timeline Estimate

- **Phase 1 (UI):** 1-2 days (✅ Complete)
- **Phase 2 (DynamoDB + Lambda updates):** 3-5 days
- **Phase 3 (S3 restructuring):** 2-3 days
- **Phase 4 (Enable multi-domain):** 1-2 days
- **Phase 5 (Domain API):** 1-2 days
- **Testing & validation:** 2-3 days

**Total:** 2-3 weeks for full implementation

## Conclusion

The multi-domain support requires changes across the entire stack but can be implemented incrementally with minimal risk. The recommended approach uses a single S3 bucket with domain prefixes and DynamoDB for permission management, providing a good balance of simplicity and flexibility.
