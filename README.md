## RHBK Optimized Container Image Build and deployment Automation

The new release of Red Hat Build of Keycloak (RHBK) the new name for what was fomerly known as RHSSO has been simplified and above all support FIPS. 
However, due to licensing incompatibilities, Red Hat was not able to include the required Bouncy Casttle FIPS crypto libraries into the container. Instead Red Hat recommends that anyone needing strict FIPS support to rebuild the provided container to add the required libraries (jars) to be downloaded from the (BouncyCastle website)[https://bouncycastle.org/fips-java/] and specifically (from) [https://downloads.bouncycastle.org/fips-java/].

Also the approach used with RHBK is to enable more immutability and therefore the way extensions were previously done no longer works. The recommended apporach is therefore to also build the provided image to include any extensions (e.g. custom themes, spi ...) to the image. 
In order to achieve two goals with one stone we are building the image so that we can include both the Bouncy Castle required libraries for FIPS as well as the custom themes/extension jars used to further customize the deployment of keycloak. 

Another change introduced with this new release is to no longer include the database deployment with the keycloak deployment. Rather it is rightly recommended that production grade database be used. 

Finally the new release provides a tons of configuration knobs to build and deploy the resulting keycloak instance. In order make it easy for folks to get started without having to comb through the extensive documentation we see the need to provide a production ready template that can be used as a starting point. 

For all of the reason above the role is being created to not only help create an optimized FIPS ready version of the container image but also a jinja2 template along with an Ansible playbook that can be used to create and configure all necessary kubernetes artifacts needed to successful deploy the resulting optimized image.

Role Name
=========

A utility role to help build and deploy an optimized Red Hat Build of Keycloak (RHBK) to be deployed via the rhbk-operator to an OpenShift Container Platform 4.+ (OCP4). 

The main focus for this role is two folds like stated above: build an optimized image that is strict FIPS compliant and enable an easy deployment of the resulting instance based on a provided jinja2 template. 

The container build process allows for the addition of custom themes or additional libraries (e.g. extra providers to be deployed ...). 

The reason for the first focus (optimized container build) is to show how one can successfully include Bouncy Castle FIPS jars so that the optimized image can be run in strict FIPS mode. Note that even though the recommended jars are included here the playbook provide tasks to enable downloading those jars directly from the Bouncy Castle website if necessary.  In addition if extra java libraries or jars need to be included they can be placed under the context/_build/extension directory to be copied into the resulting optimized image.  

The reason for the second focus (deployment of the keycloak instance) is to make it easy to generate the necessary CR along with any needed kubernetes artifacts as well as anything required to make FIPS compliance. 

Therefore this role contains two playbooks focused on each of the main tasks: building an optimized container image and deploying the resulting keycloak instance. 

### RHBK Optimized FIPS image build
The playbook (build-optimized-rhbk-container-image.yml) and associated files allow us to build a new version of the RHBK image when a new version of the base image is available from Red Hat or whenever an update is needed (e.g. new package is required, new binaries need to be included ...). 

This playbook is used to build, tag and push two container images into the target registry. The first image is the optimized RHBK image that will be ready to support strict mode FIPS but also any additional extensions if applicable. The second image is a helper image to help create BCFKS formatted keystore and trustore from scratch using pem certificate, key and intermediate CA certificate or convert an existing JKS keystore/truststore into a BCFKS keystore/truststore. 
Note that nothing else is required for the two images to be created and pushed to the target registry except when necessary to change the base image used and if applicable adjust some of the provided key files. 

Before running this playbook you will need the extensions either already staged or you will need to set the download_extensions boolean to true and ensure the versions of the necessary file are up to date to have the playbook download the extensions for you. 

This playbook can only be run on an Internet connected bastion/jumphost host with access to the location where the extensions are hosted. If not please ensure you can download the existing extensions from the binary repository (e.g. artifactory) and stage them appropriately (the extension binaries are expected under context/_build/extensions directory). 

Once the extensions have been staged or you have updated the rhbkbuild.yml variable file to ensure that the extensions will be downloaded, you need to make sure that you also update any necessary artifacts. 
For example if additional changes are required to the java.security file included under the context/_build directory to reflect your intent.
For instance for RHBK 22 the JDK used was OpenJDK 17 and therefore the provided java.security for that branch is the same one found under the openjdk17 directory structure with the necessary configuration to make it support FIPS. 
Similarly RHBK 26 uses OpenJDK 21 and therefore the java.security file has to match the one located under the openjdk 21 directory tree with the necessary modification to support FIPS. 
If you are rebuilding for a newer version you need to ensure that you are rebaselining the java.security file. The easiest way to get a copy of that file for the new RHBK base image is to run the container image using `podman run` and then use `podman cp` to export/extract the file from the running container onto the host and then make the necessary adjustment to make it support FIPS. Use the provided file as a guide to figure out what needs to be update in the exported file. 
 
Once all of that is done, run the playbook as follows: 

```bash 
ansible-playbook --ask-vault-pass -v  build-optimized-rhbk-container-image.yml
``` 
To override the default container image name, use the following command   
```bash
ansible-playbook --ask-vault-pass -v -e download_extensions=false -e rhbk_image_name=fips-keycloak-rhel9 build-optimized-rhbk-container-image.yml 
```

### RHBK Instance deployment 
The second playbook deploy-and-configure-rhbk-keycloak.yml is used to deploy the optimized image. 
This playbook has blocks of tasks to help with the various aspects of succesfully deploying a keycloak instance. For instance if this is for a test deployment, there is a toggle to enable the deployment of postgresql statefulset to use as the required database. Note that for production deployments this database should not be used. There are also blocks to help create keystores and truststores as well as create associated secrets and configmap if necessary, all driven by toggle booleans. There are also tasks to import realms into the deployed instance of keycloak either during startup (when running in dev mode) or post container creation. 

Like in the case above ensure that the appropriate variables have been updated to reflect your intent.

Once all of that is done, run the playbook as follows: 

```bash 
ansible-playbook --ask-vault-pass -v deploy-and-configure-rhbk-keycloak.yml 
``` 

Note that before running any playbook always make sure you properly set the appropriate variables as well as any related vaulted items. 

### RHBK Realm Import
**Realm Export**
Requirements for Realm Import
Realm export by default will do a partial export (i.e. excludes groups and roles and existing clients)(see the two sample screenshoots below depending on your version of keycloak).
![](images/rhbk-export-partial.png)
![](images/keycloak-export-partial.png)

If you need to export groups and roles as well as existing clients, make sure to click on the two buttons (Export groups and roles and Export clients) on the Partial Export page (refer to the two sample screenshoots below depending on your version of keycloak)

![](images/rhbk-export-full.png)
![](images/keycloak-export-full.png)

We will refer to this export as a full export in the instructions below.

During the RHBK creation there is an option to provide a raw realm export file so that the newly provisioned RHBK will have the realm imported. In order for this to work there are a few steps required to cleanup the full export file to make it ready for import.

Note that these steps are not requried if you performed a default partial export.

1. Locate the secret code for each exported client and replace it with its equivalent secret value from the original keycloak from which the export was conducted. You can located this on the client configuration page on the admin console. 
   The value you are replacing are the `**********`. 
   Also note that if you have user federation and have bind credentials set, you will need to also decode the value in the updated json file to be able to connect to the backend identity provider.
2.  Locate the `authorizationSettings` nodes defined for each client and remove the entire node from the file. This structure is usually located under the optionalClientScopes node within the file.
3.  Save the modified json file and use that as the value for the `sso_relamimport_json` variable when deploying the keycloak RHBK instance.



Requirements
------------
A running OpenShift 4 cluster with the rhbk-operator (with a version corresponding to the version of the RHBK image used for the opetimized RHBK image build above) already deployed and with valid credentials provided through the variables described below.
A running target registry with valid credentials provided through the variables described below.
An optional RHEL 8 (or higher) Internet connected bastion host with access to the location where the extensions are hosted and access to Red Hat registry if the extensions and images are to be downloaded. If there is no need to download the image or Bouncy Castle java libraries (it is assumed that these are already available on the host or can be pulled down from the target registry) then the controller does not need to be Internet Connnected. 
Finally the controller is expected to have a few packages installed on it like podman, skopeo, jq...It is also expected to be FIPS enabled so that the built optimized image can inherit FIPS from the host it is built on. 

Dependencies
------------
This role uses the https://github.com/cadjai/ocp-cluster-login.git role to authenticate against the cluster.


Installation and Usage
-----------------------
Clone the repository to where you want to run this from and make sure you can connect to your cluster using the CLI .
Ensure you install all requirements using `ansible-galaxy install -r requirements.yml --force` before performing the next steps.
You will also need to have admin role within the namespace you are deploying into in order to run the deployment playbook.
Finally before running the playbook make sure to set and update the variables as appropriate to your use case.

Plays and Role Variables
------------------------
##### Optimized image build controlling variables
- registry_host_fqdn: FQDN of the target registry to use
- local_repository: the repository within the target registry 
- openshift_cli: Openshift client binary used to interact with the cluster api (default to 'oc')
- ocp_cluster_user: The name of the cluster user used to perform the various actions against the cluster.
- ocp_cluster_user_password: The password of the cluster user used to perform the various actions against the cluster.
- ocp_cluster_console_url: The URL of the API the cluster these actions are being applied to.
- ocp_cluster_console_port: The port on which the cluster api is listening (default to 6443)
- rhbk_image_name: name of the optimized image built
- rhbk_ks_image_name: name of the helper image for BCFKS keystore generation
- rhbk_image_containerfile: containerfile to use to build the image
- rhbk_image_build_context_dir: context directory to use during the image build
- rhbk_image_build_arg_base_image_name: base image to use
- rhbk_image_build_arg_image_label_summary_value: image label summary 
- rhbk_image_build_arg_image_label_name_value: image label if necessary
- rhbk_image_build_arg_image_label_maintainer_value: image maintainer info
- disable_layer_caching: to disable layer caching
- squash_layers: if layer squashing is required for the image 
##### Client download controlling variables
- download_extensions: false
- extensions:
  ```
    bc-fips:
      url: URL to download jar from Bouncy Castle website (e.g. 'https://downloads.bouncycastle.org/fips-java/')
      pkg_version: version of the package to download
      pkg_name: name of the package
      pkg_suffix: suffix to append to the package name
      pkg_extention: package name extension
  ```
##### Keycloak instance deployment controlling variables
- rhbk_ns: namespace the keycloak instance and operators and being deployed into
- registry_authfile: the authfile for the registry where the optimized keycloak instance is comes from
- deploy_pgsql: whether to deploy a postgresql DB statefulset. Only used for testing
- rhbk_db_secret_name: name of the secret holding postgresql credentials
- rhbk_db_svc_name: service name for the keycloak DB if deployed as a service
- rhbk_db_port: postgresql DB port
- rhbk_db_password: postgresql DB password
- rhbk_db_username: username of the postgresql DB 
- rhbk_db_pvc_name: name of the pvc for thepostgresql DB 
- rhbk_db_pvc_size: size of the pvc for hte postgresql DB
- create_bcfks_keystore: wether to create a BCFKS keystore
- jks_ks_file: JKS keystore file if one is to be converted into BCFKS
- jks_ks_password: JKS keystore password if one is being converted to BCFKS
- rhbk_image: RHBK optimized image being used to deploy the keycoak instance 
- rhbk_image_tag: RHBK optimized image tag
- rhbk_ks_image: image used to generate or convert JKS keystore into BCFKS
- rhbk_ks_image_tag: tag for the image used to generate BCFKS keystore
- create_bcfks_truststore: whether we want to generate a BCFKS truststore
- jks_ts_file: JKS truststore file if one is to be converted into BCFKS
- jks_ts_password: JKS truststore password if one is being converted to BCFKS
- create_keystore_secret: wether to create a secret for the keystore being used
- bcks_file: BCFKS keystore file path
- bcks_password: BCFKS keystore password. At least 14 characters required
- rhbk_ks_secret_name: name to use for the keystore secret
- rhbk_db_host_name: hostname or IP or service name of the postgresql DB to use to connect to the DB
- create_truststore_cm: wether we want to create the truststire configmap or not
- rhbk_ts_cm_name: name of the truststore configmap
- bcts_file: BCFKS truststore file path
- bcts_password: BCFKS truststore password. At least 14 characters required
- rhbk_ks_type: type of the keystore. for strict FIPS BCFKS is required but can be JKS or PKCS12
- rhbk_ts_type: type of the keystore. for strict FIPS BCFKS is required but can be JKS or PKCS12
- rhbk_hostname: optional hostname for the keycloak instance. Default uses route for the app
- rhbk_admin_url: optional admin console URL for the keycloak instance. Default uses route for the app
- config_custom_theme: if custom theme is to be added along with related environment variables
- custom_theme_env: structure for custom theme environment variables
  ```
  - name: name of the environment variable
    value: value of the environment variable 
  - name: name of the environment variable
    value: value of the environment variable
  ``` 
- deploy_sso_instance: if we want to deploy the keycloak instance
- rhbk_instance_count: number of keycloak instance replica
- sso_relamimport_yaml: path to the yaml formated realm import if one is being applied
- sso_relamimport_json: path to raw json realm export file to be imported if needed
- apply_realm_import: if a realm imprt is being performed
- apply_import_on_start: if a realm import needed to be performed at startup. Only used for dev mode srtart
- rhbk_realm_import_cm: realm import configmap if used during startup
- rhbk_db_pool_initial_size: postgresql DB initial pool size
- rhbk_db_pool_min_size: postgresql DB min pool size
- rhbk_db_pool_max_size: postgresql DB max pool size
- rhbk_cert_file: pem formatted cert for the RHBK instance if creating BCFKS keystore from that
- rhbk_key_file: pem formatted key for the RHBK instance if creating BCFKS keystore from that
- rhbk_intca_cert_file: pem formatted intermediate cert for the RHBK instance if creating BCFKS keystore from that
- rhbk_ca_cert_file: pem formatted CA cert for the RHBK instance if creating BCFKS truststore from that
- generate_truststore: if we are generating the BCFKS truststore from scratch
- generate_keystore: if we are generating the BCFKS keystore from scratch
- convert_jks: if we are converting a JKS keystore/truststore  to a BCFKS keystore/truststore
- realm_name: name of the realm being imported


License
-------

BSD

Author Information
------------------

An optional section for the role authors to include contact information, or a website (HTML is not allowed).
