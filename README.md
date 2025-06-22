# terraform-aws-iam-identity-center

## 🌩️ Part of YROS Cloud Blueprints

Terraform module to manage **AWS IAM Identity Center** (formerly AWS SSO) with:

- Group creation in the Identity Store
- Permission Sets with AWS and Customer Managed Policies
- Account Assignments per team and allowed accounts

---

## 🚀 Features

- 🔐 Creates IAM Identity Center groups based on teams
- 🧾 Creates permission sets using AWS-managed and customer-managed policies
- 🗂️ Assigns groups to specific AWS accounts via allowed accounts mapping
- ⏱️ Configurable session duration per team using ISO 8601 duration (e.g., `PT4H`, `PT12H`)
- 🔁 Dynamic account + group mapping using a single input

---

## 📦 Usage

```hcl
module "identity_center" {
  source = "yros-cloud/iam-identity-center/aws"

  teams = {
    DevTeam = {
      description       = "Developers"
      allowed_accounts  = ["dev", "staging"]
      permission_set = {
        description               = "Developer full access to AWS"
        session_duration          = "PT8H"
        aws_managed_policies     = ["arn:aws:iam::aws:policy/PowerUserAccess"]
        customer_managed_policies = []
      }
    }

    SecurityTeam = {
      description       = "Security team"
      allowed_accounts  = ["dev", "staging"]
      permission_set = {
        description               = "Read-only and custom access"
        session_duration          = "PT4H"
        aws_managed_policies     = [
          "arn:aws:iam::aws:policy/ReadOnlyAccess",
          "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
        ]
        customer_managed_policies = [
          "s3-limited-access",
          "s3cost-viewer"
        ]
      }
    }
  }

  accounts_aws = {
    dev     = { id = "111122223333" }
    staging = { id = "444455556666" }
  }
}

## 🔧 Inputs

| Name          | Description                                                                                         | Type           | Required |
|---------------|-----------------------------------------------------------------------------------------------------|----------------|----------|
| `teams`       | Map of team configs. Each must include `description`, `allowed_accounts`, and `permission_set`.     | `map(object)`  | ✅ Yes   |
|               | Each `permission_set` must include: `description`, `aws_managed_policies`, `customer_managed_policies`, and optional `session_duration` (default `"PT12H"`) |                |          |
| `accounts_aws`| Map of AWS accounts (`key = alias`, `value = { id = "123456..." }`)                                 | `map(object)`  | ✅ Yes   |

---

## 📄 Outputs

| Name                   | Description                                                  |
|------------------------|--------------------------------------------------------------|
| `identitystore_groups` | Map of groups created in the Identity Store                  |
| `permission_sets`      | Map of permission sets created with their details            |
| `account_assignments`  | Map of group assignments to accounts and permission sets     |

---

## 🧐 Notes

- This module requires **AWS IAM Identity Center** to be enabled in the AWS Organization.
- `session_duration` follows [ISO 8601 duration format](https://en.wikipedia.org/wiki/ISO_8601#Durations). Examples:
  - `PT1H` (1 hour)
  - `PT4H` (4 hours)
  - `PT8H` (8 hours)
  - `PT12H` (default)
  - `PT24H` (max allowed by IAM Identity Center)
- If `session_duration` is not specified for a team, it defaults to `"PT12H"`.
- Custom managed policies must already exist in the **target AWS account**.
- Values in `allowed_accounts` must reference keys defined in `accounts_aws`.
- The Identity Store is automatically discovered via the current AWS credentials.

---

## 📘 Example

See the [`examples/basic`](./examples/basic) folder for a complete working example.

---

## 📝 License

MIT — see [LICENSE](./LICENSE) file.
