# Cognito Authentication Setup Guide

This guide walks you through deploying a NEW Cognito authentication system for the Goal Pyramid website with Google OAuth.

## Prerequisites

You'll need to set up Google OAuth credentials. This will allow users to sign in with their Google accounts.

## Step 1: Set Up Google OAuth Credentials

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Go to **APIs & Services** → **Credentials**
4. Click **Create Credentials** → **OAuth 2.0 Client ID**
5. Configure the OAuth consent screen if prompted:
   - User Type: External
   - App name: Goal Pyramid
   - User support email: Your email
   - Developer contact: Your email
6. Create OAuth 2.0 Client ID:
   - Application type: **Web application**
   - Name: Goal Pyramid Auth
   - Authorized JavaScript origins: (leave empty for now)
   - Authorized redirect URIs:
     - `https://goal-pyramid-auth.auth.ap-southeast-2.amazoncognito.com/oauth2/idpresponse`
   - Click **Create**
7. **Copy the Client ID and Client Secret** - you'll need these!

## Step 2: Update Terraform Variables

Edit `terraform/variables.tf` and update these values:

### Google OAuth Credentials

```hcl
variable "google_client_id" {
  description = "Google OAuth Client ID"
  type        = string
  default     = "YOUR_GOOGLE_CLIENT_ID_HERE"  # From Step 1
  sensitive   = true
}

variable "google_client_secret" {
  description = "Google OAuth Client Secret"
  type        = string
  default     = "YOUR_GOOGLE_CLIENT_SECRET_HERE"  # From Step 1
  sensitive   = true
}
```

### Bucket Name (must be globally unique)

```hcl
variable "bucket_name" {
  description = "Name of the S3 bucket for website hosting (must be globally unique)"
  type        = string
  default     = "goal-pyramid-website-YOUR_NAME"  # Make this unique across all of AWS
}
```

### Cognito Domain Prefix (must be globally unique)

```hcl
variable "cognito_domain_prefix" {
  description = "Prefix for Cognito hosted UI domain"
  type        = string
  default     = "goal-pyramid-auth-YOUR_NAME"  # Make this unique
}
```

## Step 3: Bootstrap Terraform (First Time Only)

If you haven't run the bootstrap workflow yet:

1. Go to GitHub Actions
2. Run "Bootstrap Terraform State Backend"
3. Wait for completion

## Step 4: Deploy Infrastructure

Run the deployment workflow:

1. Go to GitHub Actions
2. Run "Deploy to AWS" workflow
3. Wait for completion (this will create your Cognito user pool, API Gateway, Lambda functions, etc.)

## Step 5: Get Terraform Outputs

After deployment, get these values from Terraform outputs:

```bash
cd terraform
terraform output cognito_user_pool_id
terraform output cognito_client_id
terraform output cognito_domain
terraform output api_url
terraform output website_url
```

Save these values - you'll need them!

## Step 6: Update Frontend Configuration

Edit `src/website/config.js` with the actual values from Terraform outputs:

```javascript
const CONFIG = {
  COGNITO_DOMAIN: 'goal-pyramid-auth.auth.ap-southeast-2.amazoncognito.com',  // From terraform output
  CLIENT_ID: 'YOUR_ACTUAL_CLIENT_ID',  // From terraform output cognito_client_id
  API_URL: 'YOUR_ACTUAL_API_URL'       // From terraform output api_url
};
```

## Step 7: Update Cognito Callback URLs

Now that you have your CloudFront URL, you need to update Cognito:

1. Go to AWS Console → Cognito → User Pools
2. Select **"goal-pyramid-user-pool"**
3. Go to "App integration" tab
4. Find the **"goal-pyramid-web-client"** app client
5. Click "Edit" in the Hosted UI settings
6. Update the callback URLs with your actual CloudFront URL:
   - **Allowed callback URLs:**
     - `https://YOUR_CLOUDFRONT_URL/index.html`
     - `https://YOUR_CLOUDFRONT_URL/`
   - **Allowed sign-out URLs:**
     - `https://YOUR_CLOUDFRONT_URL/index.html`
7. Save changes

## Step 8: Update Google OAuth Redirect URI

Go back to Google Cloud Console and update the authorized redirect URI:

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Go to **APIs & Services** → **Credentials**
3. Click on your OAuth 2.0 Client ID
4. Under **Authorized redirect URIs**, make sure you have:
   - `https://goal-pyramid-auth.auth.ap-southeast-2.amazoncognito.com/oauth2/idpresponse`
   - (or your actual cognito domain if you changed the prefix)
5. Save

## Step 9: Redeploy Website

After updating `config.js`:

1. Commit and push changes
2. GitHub Actions will automatically redeploy
3. Or manually run "Deploy to AWS" workflow

## Step 10: Test Authentication Flow

1. Visit your CloudFront URL
2. Click "Sign in with Google"
3. Complete authentication
4. Fill out onboarding form
5. Verify you reach the home page

## File Structure Created

### Terraform (Infrastructure)
- `terraform/cognito.tf` - Cognito app client configuration
- `terraform/profile_api.tf` - API Gateway, Lambda, DynamoDB for profiles
- `terraform/variables.tf` - Updated with Cognito variables
- `terraform/outputs.tf` - Updated with Cognito and API outputs

### Backend (Lambda Functions)
- `src/api/utils/` - Helper utilities
  - `__init__.py`
  - `helpers.py`
  - `response_builder.py`
  - `validators.py`
- `src/api/profiles/` - Profile API endpoints
  - `create_profile.py`
  - `get_profile.py`
  - `update_profile.py`

### Frontend (Website)
- `src/website/config.js` - Cognito configuration
- `src/website/auth.js` - Authentication logic
- `src/website/utils.js` - JWT and utility functions
- `src/website/api-client.js` - API request wrapper
- `src/website/profile-api.js` - Profile API client
- `src/website/validators.js` - Form validation
- `src/website/onboarding.html` - User onboarding page
- `src/website/onboarding.js` - Onboarding logic
- `src/website/home.html` - Authenticated home page
- `src/website/home.js` - Home page logic
- Updated `src/website/index.html` - Landing with login
- Updated `src/website/index.js` - OAuth callback handling
- Updated `src/website/navbar.html` - Auth-aware navbar
- Updated `src/website/navbar.js` - User info display
- Updated `src/website/styles.css` - Auth UI styling

## Troubleshooting

### Error: "Not authenticated"
- Check if config.js has correct CLIENT_ID and API_URL
- Clear browser localStorage and try login again

### Error: "Profile not found"
- User needs to complete onboarding
- Check DynamoDB table has correct items

### Login redirects to error page
- Verify callback URLs in Cognito match your CloudFront URL exactly
- Check browser console for errors

### API calls fail with 401
- Token may be expired - try logging out and back in
- Check API Gateway has Cognito authorizer configured correctly

## Next Steps

After authentication is working:
1. Add goal creation features
2. Implement pyramid visualization
3. Add block tracking functionality

## Important Notes

- Goal Pyramid has its own **completely separate** Cognito User Pool
- Users are **independent** from PoliticNZ - different login system
- Goal Pyramid has its own DynamoDB tables for user data
- Google OAuth credentials can be shared or separate from PoliticNZ

## Security Best Practices

- **Never commit** Google Client ID/Secret to Git
- Use environment variables or AWS Secrets Manager for production
- The variables in `variables.tf` marked as `sensitive = true` won't show in Terraform outputs
- Consider using GitHub Secrets for CI/CD instead of hardcoding in Terraform

