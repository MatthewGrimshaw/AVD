@description('The name of the host pool resource.')
param name string

@description('The location of the resource group to which the host pool belongs.')
param location string = resourceGroup().location

@description('The tags of the host pool resource.')
param tags object

@description('Time zone for maintenance as defined in https://docs.microsoft.com/dotnet/api/system.timezoneinfo.findsystemtimezonebyid')
param maintenanceWindowTimeZone string

@allowed(['Friday', 'Monday', 'Saturday', 'Sunday', 'Thursday', 'Tuesday', 'Wednesday'])
param dayOfWeek string

@description('The update start hour of the day. (0 - 23)')
param hour int

@description('	The type of maintenance for session host components')
@allowed(['Default', 'Scheduled'])
param type string

@description('Whether to use localTime of the virtual machine for maintenance windows')
param useSessionHostLocalTime bool

@description('The Custom rdp property of HostPool. ')
param customRdpProperty string

@allowed(['BYODesktop', 'Pooled', 'Personal'])
param hostPoolType string

@description('The description of HostPool')
param hostPooldescription string

@description('Friendly name of HostPool.')
param friendlyName string

@description ('The max session limit of HostPool')
param maxSessionLimit int

@description ('The load balancer type of HostPool')
@allowed(['BreadthFirst', 'DepthFirst', 'Persistent'])
param loadBalancerType string

@description('PersonalDesktopAssignment type for HostPool.')
@allowed(['Automatic', 'Direct'])
param personalDesktopAssignmentType string

@description('The type of preferred application group type for HostPool.')
@allowed(['Desktop', 'None'])
param preferredAppGroupType string

@description('The flag to turn on/off StartVMOnConnect feature.')
@allowed([true, false])
param startVMOnConnect bool

module avdHostPool 'bicep/hostpool.bicep' = {
  name: name
  params: {
    name: name
    location: location
    tags: tags
    hostPoolType: hostPoolType
    hostPooldescription: hostPooldescription
    friendlyName: friendlyName
    maxSessionLimit: maxSessionLimit
    loadBalancerType: loadBalancerType
    personalDesktopAssignmentType: personalDesktopAssignmentType
    preferredAppGroupType: preferredAppGroupType
    startVMOnConnect: startVMOnConnect
    customRdpProperty: customRdpProperty
    dayOfWeek: dayOfWeek
    hour: hour
    maintenanceWindowTimeZone: maintenanceWindowTimeZone
    type: type
    useSessionHostLocalTime: useSessionHostLocalTime
  }
}

