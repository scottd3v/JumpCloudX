## What You Need to Know: The JumpCloud Agent

**Before** attempting to install the JumpCloud Agent on a system, first ensure that the target system you intend to install the agent on is running a [supported operating system](https://support.jumpcloud.com/customer/portal/articles/2390451) and meets the basic requirements for agent installation.

The most important requirement that must be met to install the JumpCloud Agent on a system is that the target system cannot be bound to a **Windows Domain** or  directory service like **Open Directory**.

Regardless of operating system the JumpCloud agent **cannot be installed** on machines that are **bound to a Windows Domain** or configured to sync with an existing directory like **Open Directory**.
  * To install the JumpCloud agent on a system that is bound to a Windows Domain or a Directory Service the target system must first be removed from the Windows domain or associated directory prior to installing the JumpCloud agent.

#### Troubleshooting Tip:   

The JumpCloud agent can only takeover existing local system user accounts. Any **Domain** or **Mobile** user accounts must be converted to local system accounts prior to JumpCloud agent installation and account takeover.

|Percent Complete|0%|
|-------------| -------------  |
|[Previous Page]()|[Next Page]()|