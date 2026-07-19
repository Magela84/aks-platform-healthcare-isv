AKS Platform Migration – Healthcare ISV EngagementOverviewThis project showcases the migration of four patient-facing applications from individual Azure Virtual Machines to a managed Azure Kubernetes Service (AKS) platform. The goal was to achieve tenant isolation, automated scaling, and standardized deployments for a healthcare Independent Software Vendor (ISV).Problem StatementThe ISV faced major operational challenges:
Manual scaling was required, as VMs needed resizing during peak clinic hours.
Inconsistent patching across four separate VMs increased security risk.
No standardized deployment process existed across the application teams, leading to inefficiencies.
What I Built
AKS cluster with dedicated system and user node pools
System node pool restricted to cluster internals only
User node pool with autoscaling (1–4 nodes)
Reusable Helm chart for all four patient applications
Per-application values files for easy customization
Namespace-level RBAC with ServiceAccount for each team
Default-deny NetworkPolicy between namespaces
Horizontal Pod Autoscaler (HPA) for each application
Azure Container Registry (ACR) with Managed Identity pull access
GitHub Actions pipeline using OIDC authentication
ArchitectureEach patient application is deployed in its own namespace with autoscaling:
patient-portal: HPA, 3–12 pods
appointments: HPA, 2–8 pods
telehealth: HPA, 2–10 pods
billing: HPA, 1–4 pods
Technologies Used
Kubernetes, AKS
Helm, Terraform
Azure Container Registry
Managed Identities
GitHub Actions
RBAC, NetworkPolicy
Log Analytics
Python, Flask
Subscription NoteAKS cluster provisioning may be restricted on free Azure subscriptions due to VM quota limits. The provided Terraform code is production-ready and validated. All other resources (ACR, Log Analytics, etc.) were deployed and tested successfully.Usage
Clone the repo:
git clone https://github.com/Magela84/aks-platform-healthcare-isv.git

Deploy infrastructure using the Terraform scripts.
Customize values files for each application.
Use the GitHub Actions pipeline for automated deployments.
Monitor and manage applications using Log Analytics and AKS native tools.
Engagement Outcome
Delivered a standardized Kubernetes platform with tenant isolation and automatic scaling.
Established a consistent Helm-based deployment process across all patient applications.
Simplified operations and improved security posture for the healthcare ISV.
AuthorMagela Bobby Akinola
LinkedIn | Portfolio | GitHub
