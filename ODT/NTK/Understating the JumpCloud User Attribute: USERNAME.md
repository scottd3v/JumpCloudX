## Understating the JumpCloud User Attribute: USERNAME

The JumpCloud USERNAME is the **most important** JumpCloud user attribute to fully understand before creating or importing users into JumpCloud because once a JumpCloud user is created the USERNAME is **not modifiable**.

JumpCloud users authenticate to JumpCloud managed systems and to JumpClouds Radius-as-a-Service using their JumpCloud username.

Special consideration should be given to the naming convention used when populating the USERNAME field when creating users if you intend to **takeover existing system user accounts** using the JumpCloud agent.

  * In order for the JumpCloud agent to **takeover an existing system user account** the USERNAME of the JumpCloud user bound to the machine must match **identically** with the USERNAME of the existing local system account for the account takeover to occur.

    * If there is **any** mismatch  a new local user account on the system will be created and account takeover will not occur.

#### Expert Advice:     

If you wish to rename the username of a JumpCloud user the best practice is to delete the user and then recreate them with the updated username.


|Percent Complete|0%|
|-------------| -------------  |
|[Previous Page]()|[Next Page]()|