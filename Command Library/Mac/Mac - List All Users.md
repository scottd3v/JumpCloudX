#### Name

Mac - List All Users

#### commandType

mac

#### Command

```
dscl . list /Users | grep -v '^_' | grep -v 'daemon' | grep -v 'nobody' | grep -v 'root'
```

#### Description


#### *Import This Command*

To import this command into your JumpCloud tenant run the below command using the [JumpCloud PowerShell Module](https://github.com/TheJumpCloud/support/wiki/Installing-the-JumpCloud-PowerShell-Module)

```
Import-JCCommand -URL 'Create and enter Git.io URL'
```
