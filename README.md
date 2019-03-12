---
services: service-fabric
platforms: dotnet, windows
author: raunakpandya, vipulm-msft, prashantbhutani90
---

# service-fabric-autoscale-helper
Service Fabric application that aids managing, autoscaling nodes in VMSS based [Microsoft Azure Service Fabric](https://azure.microsoft.com/services/service-fabric/) cluster.

## Guidelines for running a stateless only workloads on Service Fabric cluster
If you plan to run stateless only workload which is configured to auto scale in or out based on some pattern, it is recommended to follow these guidelines: 

- Do not scale primary the node type
- Add another node type that is for running the stateless workload, set the durability tier for this node type to Bronze.
- Configure autoscaling rules for that new node type
- Deploy the Service Fabric auto scale helper application on the cluster, to remove the scaled-in down nodes from the cluster.

## About this application
While running statless workloads, its advisable to set the [durability tier](https://docs.microsoft.com/en-us/azure/service-fabric/service-fabric-cluster-capacity#the-durability-characteristics-of-the-cluster) of the node type as Bronze. This ensures faster scale outs and avoiding scenarios like scale in getting stuck. However, this also results in removed nodes/ VM instances [displayed as unhealthy](https://docs.microsoft.com/en-us/azure/service-fabric/service-fabric-cluster-scale-up-down#behaviors-you-may-observe-in-service-fabric-explorer) in the Service Fabric explorer. To remove them, one needs to explicitly invoke [Remove-ServiceFabricNodeState](https://docs.microsoft.com/en-us/powershell/module/servicefabric/remove-servicefabricnodestate?view=azureservicefabricps) on that node name. The Service Fabric auto scale helper application essentially takes care of removing nodes if they are down for a long period of time by triggering Remove-ServiceFabricNodeState. 

## Application Parameters
The application exposes set of application parameters which allows users to customize the application deployment as per their needs. 

### Parameter Descripiton
|Parameter|Description|
|:-|:-|
|NodeManagerActorService_ScanIntervalInSeconds|How often the application should scan for the nodes ready for removal. <br/><br/>Default value is `60` seconds.|
|NodeManagerActorService_ClientOperationTimeoutInSeconds|How long does the client wait for the response from cluster. <br/><br/>Default value is `30` seconds.|
|NodeManagerActorService_DownNodeGraceIntervalInSeconds|How long the node should be down for the service to consider it gone for good. <br/><br/>Default value is `120` seconds.|
|NodeManagerActorService_SkipNodesUnderFabricUpgrade|The service should consider nodes under fabric upgrade for removal or not.  <br/><br/>Default value is `true`.|
|NodeManagerActorService_PlacementConstraints|Placement constraints with which the service must be deployed. Ideally one should put placement constraints to deploy the application on the primary node type.<br/><br/>Default value is empty.|

## Usage

### Build Application
To build the application you need to first setup the machine for Service Fabric application development. 

[Setup your development environment with Visual Studio 2017](https://docs.microsoft.com/azure/service-fabric/service-fabric-get-started).

Once setup, open PowerShell command prompt and run `build.ps1` script. It should produce an output like below.

```PowerShell
PS E:\service-fabric-autoscale-helper> .\build.ps1
Restore completed in 46.43 ms for E:\service-fabric-autoscale-helper\src\AutoscaleManager\NodeManager\NodeManager.csproj
.
Restore completed in 46.43 ms for E:\service-fabric-autoscale-helper\src\AutoscaleManager\NodeManager.Interfaces\NodeMan
ager.Interfaces.csproj.
Restore completed in 1.22 ms for E:\service-fabric-autoscale-helper\src\AutoscaleManager\NodeManager.Interfaces\NodeMana
ger.Interfaces.csproj.
Restore completed in 1.26 ms for E:\service-fabric-autoscale-helper\src\AutoscaleManager\NodeManager\NodeManager.csproj.
NodeManager.Interfaces -> E:\service-fabric-autoscale-helper\src\AutoscaleManager\NodeManager.Interfaces\bin\Release\net
coreapp2.0\win7-x64\NodeManager.Interfaces.dll
NodeManager -> E:\service-fabric-autoscale-helper\src\AutoscaleManager\NodeManager\bin\Release\netcoreapp2.0\win7-x64\No
deManager.dll
NodeManager.Interfaces -> E:\service-fabric-autoscale-helper\src\AutoscaleManager\NodeManager.Interfaces\bin\Release\net
coreapp2.0\win7-x64\NodeManager.Interfaces.dll
NodeManager -> E:\service-fabric-autoscale-helper\src\AutoscaleManager\NodeManager\bin\Release\netcoreapp2.0\win7-x64\No
deManager.dll
NodeManager -> E:\service-fabric-autoscale-helper\src\AutoscaleManager\AutoscaleManager\pkg\Release\NodeManagerPkg\Code\
AutoscaleManager -> E:\service-fabric-autoscale-helper\src\AutoscaleManager\AutoscaleManager\pkg\Release
PS E:\service-fabric-autoscale-helper>
```

By default the script will create a `release` package of the application in `src\AutoscaleManager\AutoscaleManager\pkg\Release` folder. 

### Deploy Application

- Open PowerShell command prompt and go to the root of the repository.

- Connect to the Service Fabric Cluster where you want to deploy the application using [`Connect-ServiceFabricCluster`](https://docs.microsoft.com/en-us/powershell/module/servicefabric/connect-servicefabriccluster?view=azureservicefabricps) PowerShell command. 

- Deploy the application using the following PowerShell command.

  ```PowerShell
  . src\AutoscaleManager\AutoscaleManager\Scripts\Deploy-FabricApplication.ps1 -ApplicationPackagePath 'src\AutoscaleManager\AutoscaleManager\pkg\Release' -PublishProfileFile 'src\AutoscaleManager\AutoscaleManager\PublishProfiles\Cloud.xml' -UseExistingClusterConnection -ApplicationParameter @{ 'NodeManagerActorService_PlacementConstraints'='(NodeTypeName==<primary_nodetype_name>)'; }
  ```

- Deploy the application using the following PowerShell command, in case you want to change the application parameters default values. You can choose any number of the aforementioned `application parameters` in any combination with this command.

  ```PowerShell
  . src\AutoscaleManager\AutoscaleManager\Scripts\Deploy-FabricApplication.ps1 -ApplicationPackagePath 'src\AutoscaleManager\AutoscaleManager\pkg\Release' -PublishProfileFile 'src\AutoscaleManager\AutoscaleManager\PublishProfiles\Cloud.xml' -UseExistingClusterConnection -ApplicationParameter @{ 'NodeManagerActorService_PlacementConstraints'='(NodeTypeName==<primary_nodetype_name>)'; 'NodeManagerActorService_ScanIntervalInSeconds'='120'; 'NodeManagerActorService_ClientOperationTimeoutInSeconds'='120'; 'NodeManagerActorService_DownNodeGraceIntervalInSeconds' = '300'; }
  ```

# Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit https://cla.microsoft.com.

When you submit a pull request, a CLA-bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., label, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.