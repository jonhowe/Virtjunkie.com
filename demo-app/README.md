![Success Workflow](https://github.com/spectral-corp/spectral-goat/workflows/scan-passed/badge.svg)
![Failure Workflow](https://github.com/spectral-corp/spectral-goat/workflows/scan-failed/badge.svg)

![](media/cover.png)

# Codesec Goat

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->


  - [Repo Breakdown](#repo-breakdown)
- [Codesec Goat](#codesec-goat)
  - [Repo Breakdown](#repo-breakdown)
- [Spectral Scan](#spectral-scan)
  - [Finding Issues with a Security Pipeline](#finding-issues-with-a-security-pipeline)
  - [Integrating into your CI](#integrating-into-your-ci)
  - [Finding Issues with a Git Precommit Hook](#finding-issues-with-a-git-precommit-hook)
  - [Tweaking Ignores](#tweaking-ignores)
    - [Glob Ignores](#glob-ignores)
    - [Rule Ignores](#rule-ignores)
    - [Match Ignores](#match-ignores)
      - [Fingerprinting](#fingerprinting)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

A security testbed, vulnerable by design for testing codesec pipeline solutions.

_Why "goat"?_
> A common saying is that if your fence won't hold water, it won't hold a goat. Animals are very creative, and will find a way around your barriers. In the same funny analogy, a _goat repo_ demonstrates creativity and deliberate security issues that you might not expect.

## Repo Breakdown 
Includes a combination of:

* Secrets, access control, hardcoding across many providers and systems
* 3rd party services
* 3rd party vendors + misconfiguration
* Non programming language assets
* Out of band assets (such as binary data)
* By-design overhead (large projects)
* Developer workflows: CI, pre-commit
* Extensibility and customizations

Designed to test and showcase:

* Coverage and value for sensitive, high risk, access control data
* High cloud services scenarios
* High open source usage integration scenarios
* Code security as a whole (full asset scan)
* Speed and efficiency of complex scans
* Ease of integration and developer experience

# Spectral Scan

In this section, we'll show you how Spectral Scan operates within these codesec issues, and we'll demonstrate the benefits you can get, by using Spectral as a one stop shop for your code security needs.

## Finding Issues with a Security Pipeline

There are two workflows in the CI:

* One that demonstrates [success](.github/workflows/success.yml) -- which means no findings, and,
* One that demonstrates [failure](.github/workflows/failure.yml) -- which means Spectral Scan has findings that need to be addressed. 

The [success](.github/workflows/success.yml) workflow run on a repository that has no findings, while the [failure](.github/workflows/failure.yml) workflow runs on the whole repository which we know has a many codesec issues such as hardcoded credential, sensitive access control detail, Terraform and Kubernetes security misconfiguration and more.

Note that the workflow is based on a `schedule` and not on `push` or `pr` to simulate activity in a Github repository.

The results can be shown in [Github Actions](https://github.com/spectral-corp/spectral-goat/actions).    

## Integrating into your CI

In this example, you'll see integration to Github Actions, but Spectral can integrate to any CI seamlessly with a one-liner:

```
curl -L your-domain/get | sh
```

Two comments regarding this one liner:

* For security best practices we _do not encourage_ piping shell scripts blindly into a shell interpreter.
* This is why we recommend getting our installer script, going over it and approving it -- and finally hosting it on your domain
* You can also get the direct binary links from us, and use in a way you prefer -- the binary is self-contained and requires no dependencies or special permissions.


Lastly, if you want to just experiment, you can use the demo script we prepared for _this_ repo:


```
$ curl -L spectralops.io/uniovauwxycdiwgr | sh
```

Spectral also has first-class integration (in our commercial offering) via plugins for the following CI services:

* CircleCI (via Orb)
* Jenkins (via custom plugin)
* Github Actions (via our own Github app)
* _And_ if your CI system has a plugin, we'll build it.


## Finding Issues with a Git Precommit Hook

This repo demonstrate the use of a Spectral Scan precommit hook, with [husky](https://github.com/typicode/husky). Spectral supports other frameworks as well as standalone precommit hooks.

With husky, it's basically this block in your `package.json`:

```json
  "husky": {
    "hooks": {
      "pre-commit": "spectral run"
    }
  },
```



## Tweaking Ignores

You can run a scan, and choose to ignore results, possibly because they're known issues, or should be addressed later, in either way -- you want to take control of your risk yourself and explicitly ignore findings. 

### Glob Ignores

You might want the same experience as working with a `.gitignore` file, ignoring an entire folder, a glob of a file structure or a specific file, regardless of any scan.

A good example might be a Tensorflow model, which weighs gigabytes, and you have reasonable certainty there couldn't be any security issues there (a fairly reasonable assumption).

To ignore using this technique, add a special `.ignore` file to your repo, and set its content much like a regular `.gitignore`

```
tf-models/*
```

When using Spectral Scan, these files will not be considered at all, when Spectral is compiling its execution plan.

### Rule Ignores

There might be a case where you want to ignore a specific rule, and under that rule, ignore a specific set of files.

For example, you want to ignore all credit cards showing under a "test" folder. In that case, you want to specify the `PCI` rule and under it specify a file glob such as `tests/.*`. In this case we use a _regular expression_ which is a bit more costly than a glob but much more powerful and expressive.

An example for how to ignore a specific file under a particular rule can be found here: [ignores.yaml](.spectral/ignores.yaml)

### Match Ignores


Lastly, you have the option of ignoring matches. This ignore feature is the most powerful, and you're able to specify actual finding text to ignore such as test keys, demo keys, and more.

Ignoring matches after they were found, is called "match_ignores" in Spectral. Example: [.spectral/spectral.yaml](.spectral/spectral.yaml)    


Adding ignores is done by editing your main spectral configuration file (`spectral.yaml`), like below:

```yaml
match_ignores:
    ignores:
    - match_text: MYSQL_ROOT_PASSWORD
    - rule_id: <rule id, regex>
      rule_name: <rule name, regex>
      match_text: <rule id, regex>
      path: <path, regex>
      match_fingerprint: b76fe610abe3bdaa92d4002dc0516dfa21c2dbf520373c6203469d0dee369888
```

You can specify a list of ignores, and each ignore can have the following fields:


#### Fingerprinting

When you want to ignore a secret, or a piece of confidential text, it doesn't make sense to specify it verbatim as an ignore because you'd be duplicating the secret. For this case, we use a cryptographically secure digest fingerprinting. To fingerprint your piece of text, you can use Spectral itself:

Example from [credentials.json](src/secrets/aws/credentials.json)
```
$ spectral fingerprint --text AKIAXXXXXXXXXXXXXXXX
b76fe610abe3bdaa92d4002dc0516dfa21c2dbf520373c6203469d0dee369888
```

Then, you can safely add this fingerprint to your ignore rule, which will ignore the content behind the fingerprint.



