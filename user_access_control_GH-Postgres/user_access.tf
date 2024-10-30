/* 
  ┌──────────────────────────────────────────────────────────────────────────┐
  │ Set Variables                                                            │
  └──────────────────────────────────────────────────────────────────────────┘
 */
locals {
  # Read in users and their membership creds - from CSV file
  users_csv = file("${path.module}/users.csv")
  users     = csvdecode(local.users_csv)

  # Processing GitHub users from csv
  github_user = { for user in local.users : user.GITHUB_USER => user }

  # Processing Postgres users from csv
  postgres_user_login = { for user in local.users : user.Employee_UID => {
    USER     = upper(user.Employee_UID)
    PASSWORD = random_password.postgres_pw[user.Employee_UID].result
    }
  }

  # Postgres Permissions
  postgres_permissions = [
    "SELECT",     ## read data permissions
    "INSERT",     ## insert data permissions
    "UPDATE",     ## update data permissions
    "DELETE",     ## delete data permissions
    "TRUNCATE",   ## truncate table permissions
    "REFERENCES", ## foreign key constraint permissions
  ]
}

/* 
  ┌──────────────────────────────────────────────────────────────────────────┐
  │ GH - User Access Control - richcontext                                   │
  └──────────────────────────────────────────────────────────────────────────┘
 */

# Grab 'engineering' team ID
data "github_team" "engineering" {
  slug = "engineering"
}

# Add users to 'richcontext' github org
resource "github_membership" "org_membership" {
  for_each = local.github_user
  username = each.key
  # Assign user as 'admin' or 'member' of organization
  role = each.value.GITHUB_ROLE == "admin,maintainer" ? "admin" : "member"
}

# Add users to 'engineering' group and assign permissions
resource "github_team_membership" "team_membership" {
  for_each = local.github_user
  username = each.key
  ## assign user as 'maintainer' or 'member' of github group
  role    = each.value.GITHUB_ROLE == "admin,maintainer" ? "maintainer" : "member"
  team_id = data.github_team.engineering.id
  ## join org first before team membership
  depends_on = [github_membership.org_membership]
}

/* 
  ┌──────────────────────────────────────────────────────────────────────────┐
  │ RDS - User Access Control - demo_app RDS Cluster (Prod + Staging)       │
  └──────────────────────────────────────────────────────────────────────────┘
 */

# Set user creds
resource "random_password" "postgres_pw" {
  for_each = { for user in local.users : user.Employee_UID => user }

  length  = 16
  special = true
}

# Create roles for users
resource "postgresql_role" "staging_postgres_user" {
  provider = postgresql.staging
  for_each = local.postgres_user_login
  ## set creds
  login    = true
  name     = each.value.USER
  password = each.value.PASSWORD
}
resource "postgresql_role" "production_postgres_user" {
  provider = postgresql.production
  for_each = local.postgres_user_login
  ## set creds
  login    = true
  name     = each.value.USER
  password = each.value.PASSWORD
}

# Set role permissions
resource "postgresql_grant" "staging_postgres_user_grant" {
  provider = postgresql.staging
  for_each = local.postgres_user_login
  role     = each.value.USER
  ## set table
  database    = var.DB_NAME
  schema      = "public"
  object_type = "table"
  ## grant permissions
  privileges = local.postgres_permissions
}
resource "postgresql_grant" "production_postgres_user_grant" {
  provider = postgresql.production
  for_each = local.postgres_user_login
  role     = each.value.USER
  ## set table
  database    = var.DB_NAME
  schema      = "public"
  object_type = "table"
  ## grant permissions
  privileges = local.postgres_permissions
}

# Send creds to Doppler
resource "doppler_secret" "staging_postgres_creds" {
  for_each = local.postgres_user_login
  provider = doppler.staging
  project  = "demo_app"
  config   = "staging"
  ## save creds
  name  = each.value.USER
  value = each.value.PASSWORD
}
resource "doppler_secret" "production_postgres_creds" {
  for_each = local.postgres_user_login
  provider = doppler.production
  project  = "demo_app"
  config   = "prod"
  ## save creds
  name  = each.value.USER
  value = each.value.PASSWORD
}
