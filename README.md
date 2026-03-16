# hb-demo-project-zero
Bicep templates for azure deployment, hub and spoke DEMO
Hub-and-spoke topology with centralized firewall inspection


## Traffic Flows

| Flow | Path | 
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Internet → Minecraft  
| Internet `:25565` → Firewall DNAT → Spoke1 VM `10.31.0.4:25565` |
| VPN → Spoke1 | VPN Client `172.16.x.x` → VPN Gateway → Firewall → Spoke1 |
| VPN → Spoke2 | VPN Client `172.16.x.x` → VPN Gateway → Firewall → Spoke2 `:80` |
| Spoke1 → Internet | Spoke1 → Firewall → Internet (Minecraft auth on `:443`) |
| Spoke2 → Spoke1 | Spoke2 `10.32.x.x` → Firewall (ICMP) → Spoke1 `10.31.x.x` |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
---

## Stack

- **IaC:** Azure Bicep
- **Networking:** VNet peering, UDR, NSG, Azure Firewall Basic, VPN Gateway P2S
- **Auth:** Azure AD (Entra ID) + OpenVPN
- **VMs:** Ubuntu 22.04 LTS — Standard_D2as_v5
- **Workloads:** Minecraft Java 1.21 (Spoke1), Nginx status dashboard (Spoke2)

#yb
