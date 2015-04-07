Building a tableau web data connector pretty easy to start with, but
we can make writing one even easier. This article introduces a
micro-framework with the following goals:

- write Tableau data sources without writing boilerplate code
- being able to package more data sources into a single data source url
- package the connector for easy deployment


While we are targeting the browser, we'll be using NodeJS to build and
package our application. We'll touch a number of nodejs tools, and I'll
try to provide a short introduction both for the tools and for the
micro-framework, but both are out of the scope of this article.


## Prerequisites

First [install NodeJs][install node]. While most OS distributions
provide node out of the box, the packages are horribly out of date most
of the time, and node is a moving target, so try to [install one from
nodesource][nodesource].

Installing NodeJs should also install its [package manager,
<code>npm</code>][npm] for us, which we'll use for the rest of the tutorial.


## Getting the framework and testing it

Firsts lets clone the framework into a a new directory of our choosing:

```
git clone https://github.com/starschema/tableau-web-table-connector.git

cd tableau-web-table-connector
```

Lets install and fire up a server to serve our content directory. We'll
use the <code>http-server</code> package from node which provides a
comfortable command-line HTTP server for our testing.

When installing an npm package with the <code>-g</code> switch, it gets
installed globally, and available for all projects, and in our case, we
can use the <code>http-server</code> command to launch a test server

```
# Installs the http-server package globally
npm install http-server -g

# Starts a web server in the local directory
http-server dist/  -p 9090
```

Now lets check the connector in Tableau. Select the Web Data Connector
and navigate to [http://localhost:9090/][test]

...(demo screenshots)...


As you can see, the connector first allows you to select the type of
data source you want to use, asks for some parameters then loads the
data and shows you a preview of your data where you can adjust column
names and types and control which columns get imported to Tableau.


## Writing our own data source

Now that the demonstration is complete, lets take a look at the contents
of the repository:

- The <code>coffee</code> folder contains the code for the framework

- The <code>providers</code> folder contains the data sources
  themselves, each in their separate subdirectory. By default there
  should be a <code>google_docs</code> and a <code>csv</code> directory,
  with a CoffeeScript and a Jade template file in both of them.

- The <code>dist</code> folder contains the compiled code and the
  launcher <code>index.html</code>


The output code in the <code>dist</code> folder is generated using
[browserify][browserify], which allow us to use NodeJS style
modules with proper scoping, importing and exporting using CommonJS
style <code>require</code> and <code>module.exports</code>. It achieves
this by running a static analysis on the source files and capturing
require statements then resolving those, and packaging all files and
resources used into a single javascript file, in our case
<code>dist.js</code>.

To use browserify, we install it:

```
npm install -g browserify
```

After this, we can re-package our application


[install node]: https://nodejs.org/
[nodesource]: https://github.com/nodesource/distributions
[npm]: https://www.npmjs.com
[test]: http://localhost:9090/
[browserify]: http://browserify.org/
