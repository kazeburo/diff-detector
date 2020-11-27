# diff-detector

Check the difference between the results of the command. diff-detector is written to work as a mackerel check plugin.

## Usage

```
% ./diff-detector -h
Usage:
  diff-detector [OPTIONS] -- command args1 args2

Application Options:
      --identifier= indetify a file store the command result with given string
  -w, --warn        Set the error level to warning
  -v, --version     Show version

Help Options:
  -h, --help        Show this help message

```

## Example

```
% echo $(date) > date.txt
% ./diff-detector -- cat date.txt 
diff-detector OK: first time execution command: 'cat date.txt'
% ./diff-detector -- cat date.txt
diff-detector OK: no difference: ```Wed Aug 12 00:39:23 JST 2020```

% echo $(date) > date.txt     
% ./diff-detector -- cat date.txt
diff-detector CRITICAL: found difference: ```@@ -1 +1 @@
-Wed Aug 12 00:39:23 JST 2020
+Wed Aug 12 00:39:40 JST 2020```
```

## mackerel.conf example

```
[plugin.checks.uname-changed]
command = "/usr/local/bin/diff-detector -- uname -a"

[plugin.checks.passwd-changed]
command = "/usr/local/bin/diff-detector -- cat /etc/passwd"
```

## Install

Please download release page
