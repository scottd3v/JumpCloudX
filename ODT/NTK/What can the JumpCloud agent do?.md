## What can the JumpCloud agent do?

  The JumpCloud agent can:

  1. Create new local system user accounts

  2. Takeover existing local system user accounts

  3. Deploy JumpCloud commands

  4. Enforce JumpCloud system policies


The JumpCloud agent interacts with local system user accounts and has the ability to:

1. Update local user account passwords

2. Enable local user accounts

3. Disable local user accounts

The JumpCloud agent **does not** delete local user accounts when system permissions are removed from a JumpCloud managed user on a JumpCloud system.

* When a user who is bound to a system through JumpCloud is deleted or removed from the system the local account that was previously managed by JumpCloud will be put into a disabled state.

#### Expert Advice:

If you wish to use the JumpCloud agent to delete local user accounts this *can* be done using a JumpCloud command.

Be very careful and fully test any JumpCloud commands that have the ability to cause major system impact in a sandbox test environment before deploying to your production systems.

|Percent Complete|0%|
|-------------| -------------  |
|[Previous Page]()|[Next Page]()|