locals {
  # Azure built-in role names for Service Bus
  role_names = {
    sender   = "Azure Service Bus Data Sender"
    receiver = "Azure Service Bus Data Receiver"
    owner    = "Azure Service Bus Data Owner"
  }
}
