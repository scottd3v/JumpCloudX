#### Name

Mac - Update GUID | JCX 1.0

#### commandType

mac

#### Command

```
username=`echo "$username" | sed 's/\"//g'`

jcguid=`echo "$jcguid" | sed 's/\"//g'`

sudo dscl . -create /Groups/$username name $username

sudo dscl . -create /Groups/$username gid $jcguid

sudo dscl . -create /Users/$username PrimaryGroupID $jcguid
```

#### Description


#### *Import This Command*

To import this command into your JumpCloud tenant run the below command using the [JumpCloud PowerShell Module](https://github.com/TheJumpCloud/support/wiki/Installing-the-JumpCloud-PowerShell-Module)

```
Import-JCCommand -URL 'https://git.io/jccg-Mac-UpdateGUID'
```
