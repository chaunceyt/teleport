sandbox:
	@scripts/setup-environment.sh

delete-sandbox:
	@scripts/cleanup.sh

port-forwards:
	@echo "Setting up port-forwards..."
	@scripts/port-forwards.sh

teleport-admins:
	@echo "Creating tadmin accounts..."
	@scripts/create-admin-accounts.sh

setup-trusted-cluster:
	@echo "Applying trusted-cluster configuration..."
	@scripts/setup-trusted-cluster.sh

create-nodes:
	@echo "Generating creating nodes..."
	@scripts/create-nodes.sh
