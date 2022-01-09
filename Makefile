lab:
				@echo "Setting up teleport lab..."
				@scripts/setup-environment.sh

delete-lab:
				@kind delete cluster --name teleport-lab

port-forwards:
				@echo "Setting up port-forwards..."
				@scripts/port-forwards.sh

teleport-admins:
				@echo "Creating tadmin accounts..."
				@scripts/create-admin-accounts.sh

setup-trusted-cluster:
			@echo "Applying trusted-cluster configuration..."
			@scripts/setup-trusted-cluster.sh

generate-join-tokens:
		@echo "Generating join tokens..."
		@scripts/create-join-token.sh			
