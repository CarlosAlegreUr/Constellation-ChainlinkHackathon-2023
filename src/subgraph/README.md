## Setup 

We need a dependency, the Graph-CLI, let's go and install it
```bash
# NPM
$ npm install -g @graphprotocol/graph-cli

# Yarn
$ yarn global add @graphprotocol/graph-cli
```

<br>

## Deploying

For deploying this subgraph, visit [The Graph's studio](https://thegraph.com/studio/)

Click in `Create a Subgraph` and name it

After creating the subgraph you will find at your right multiple steps, we will follow the steps named `auth & deploy`

Run the commands with the corresponding with your case:

<br>

```bash
graph auth --studio <deploy_key>
```
<br>

```bash
graph codegen && graph build
```
<br>

```bash
graph deploy --studio <name_subgraph>
```

<br>

## Use it!

Now we can let it alone for some minutes to index the data and use it!!
