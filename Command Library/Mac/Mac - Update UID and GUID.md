#### Name

Mac - Update UID and GUID | JCX 1.0

#### commandType

mac

#### Command

```
username=`echo "$username" | sed 's/\"//g'`

newuid=`echo "$newuid" | sed 's/\"//g'`

olduid=`id -u $username`

sudo dscl . -change /Users/$username UniqueID $olduid $newuid

sudo dscl . -create /Groups/$username name $username

sudo dscl . -create /Groups/$username gid $newuid

sudo dscl . -create /Users/$username PrimaryGroupID $newuid

sudo find / -uid $olduid -exec chown -h $newuid {} \;

sudo shutdown -r now
```

#### Description



#### *Import This Command*

To import this command into your JumpCloud tenant run the below command using the [JumpCloud PowerShell Module](https://github.com/TheJumpCloud/support/wiki/Installing-the-JumpCloud-PowerShell-Module)

```
Import-JCCommand -URL 'Create and enter Git.io URL'
```
