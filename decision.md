Decision Log

Reasoning for the choices made in this project, written the way I'd actually explain them out loud — including what I traded off and what I'd do differently with more time or a bigger budget.

Terraform for infrastructure provisioning

Chosen over: CloudFormation, Pulumi, doing it by hand in the console.

Terraform's declarative, provider-agnostic, and the state file is a first-class concept rather than something you have to build yourself — which matters the moment you want remote state + locking, which I did. CloudFormation would've locked me into AWS-only syntax I'd have to relearn for every other cloud; Pulumi is appealing (real code instead of HCL) but for a project whose whole point is demonstrating IaC fundamentals cleanly, HCL's readability is an asset, not a limitation. Doing it by hand in the console was never a real option — it's not reproducible, and "reproducible" is the entire reason this project exists.

Remote state in S3 + locking in DynamoDB: local state works until two people (or two terminal tabs) run apply at the same time, or the laptop holding the only copy dies. S3 gives durable/versioned storage; DynamoDB's lock table turns concurrent applies from "silent corruption" into "second one waits its turn." This is boring infrastructure, but it's the kind of boring that avoids a 2am incident.

Public/private subnet split + bastion pattern

Chosen over: one flat subnet, or giving the app server a public IP directly.

The app server holds Jenkins credentials, SonarQube's DB, and eventually deploy secrets — there's no scenario where exposing it directly to the internet is the right call. The bastion pattern means there's exactly one hardened, minimal, disposable box that's internet-facing, and everything else is only reachable through it. If the bastion is compromised, the blast radius is "attacker has to also get past the private app server's own defenses" rather than "attacker is already on the box with Jenkins on it."

Trade-off: this adds a hop to every SSH session and every dashboard visit (tunnel required). I decided that's a fair price for the security model — this is exactly the kind of thing a hiring interviewer will ask "why not just skip the bastion," and the honest answer is convenience vs. attack surface, and I chose attack surface.

Ansible for configuration management (on top of Terraform)

Chosen over: Terraform user_data scripts, Chef, Puppet, doing it manually over SSH.

Terraform is good at "does this resource exist and match my config" — it's not built to be idempotently re-run against config drift on an existing box, and cramming configuration logic into user_data gives you no re-run story if step 4 of 7 fails. Ansible is agentless over SSH, which matters specifically because Terraform is the one creating the instance seconds before Ansible needs to configure it — no agent pre-install step required, unlike Chef/Puppet. Manual SSH configuration isn't repeatable and isn't something you can hand to a teammate or re-run after an instance replacement (which happened to me — the app server got swapped and I had to redo the clone + compose step from scratch; if the whole box config had been manual, that would've been a much worse day).

Docker Compose for the tool stack

Chosen over: installing Jenkins/SonarQube/Postgres/Grafana/Prometheus natively on the host.

Each of these tools wants its own Java version, its own dependency tree, and its own opinions about the filesystem. Native install turns into version conflicts fast. Compose keeps each service self-contained with its own volume, and — this is the part I actually validated, not just a textbook reason — when the app server instance was replaced mid-project, recovery was git clone → docker-compose up -d, and every service came back configured identically. That's the practical argument for containers over "it's more isolated" in the abstract: I needed the disposability, and it delivered.

Why persistent volumes specifically: containers are meant to be disposable, but Jenkins job history, SonarQube's analysis data, and Grafana dashboards are not — losing them on every docker-compose down would defeat the purpose of having them at all. Volumes decouple "the container's lifecycle" from "the data's lifecycle," which is the whole point of naming them explicitly instead of relying on anonymous volumes.

Nginx as a single reverse proxy entry point

Chosen over: exposing Jenkins/SonarQube/Grafana each on their own port.

One port (80) with path-based routing (/jenkins, /sonar, /grafana) means one security-group rule and one SSH tunnel reaches everything, instead of three of each. It also matches how this would actually be done in production, where TLS terminates at the proxy and backend services never see raw internet traffic directly — even though TLS itself is out of scope for this lab.

Jenkins for CI/CD

Chosen over: GitHub Actions.

GitHub Actions would genuinely be less setup for a project this size — that's worth saying plainly rather than pretending Jenkins was the objectively "better" choice. I went with Jenkins because the internship brief is explicitly about DevOps tooling depth, and Jenkins (self-hosted, plugin-driven, Groovy pipelines) is closer to what a lot of enterprise environments still run and is more useful to have hands-on experience with for that reason, plus it's the tool actually specified in the mini-project brief. If this were a personal project optimized purely for speed, Actions would win.

IAM role on the instance instead of access keys

Chosen over: generating an IAM user + access key pair and storing it on the box.

Access keys are long-lived credentials that sit on disk and eventually leak — via a bad .gitignore, a debug log, whatever. An IAM role attached to the EC2 instance gives temporary, auto-rotating credentials scoped to exactly S3 + CloudWatch, with nothing to leak because there's no static secret to begin with.

SSM Parameter Store for Jenkins credentials

Chosen over: hardcoding credentials in the Jenkinsfile or a .env file.

Same underlying reasoning as the IAM role point above — a hardcoded secret in a file is one accidental commit away from being in git history forever. SSM Parameter Store (SecureString, KMS-encrypted) means secrets are pulled at pipeline runtime and access is controlled by IAM policy, not by who can cat a file.

t3.micro instances + swap space (the trade-off I'll own)

Chosen because of: AWS Free Tier constraints, not because it's the "right" size for this workload.

1 GB of RAM is not enough to run Jenkins + SonarQube + Postgres + Grafana + Prometheus + Nginx concurrently — I hit that directly (CPU thrashing, near-unresponsive server) rather than reading about it. The fix was a 4 GB swap file rather than upsizing the instance, which is a real trade-off: it keeps the box inside free-tier cost, but swap is disk-backed and meaningfully slower than RAM, so this is a stopgap, not a performance fix. If cost weren't a constraint, the right answer is a bigger instance (t3.medium or larger) rather than more swap.