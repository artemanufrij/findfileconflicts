<div>
  <h1 align="center">Find File Conflicts</h1>
  <h3 align="center"><br>Helps to find file names which could have conflicts on Windows<br/>(<code>New File</code> vs. <code>new file</code>)</h3>
  <p align="center">Designed for <a href="https://elementary.io">elementary OS</a></p>
</div>

### Donate
<a href="https://www.paypal.me/ArtemAnufrij">PayPal</a> | <a href="https://liberapay.com/Artem/donate">LiberaPay</a> | <a href="https://www.patreon.com/ArtemAnufrij">Patreon</a>


<p align="center">
  coming soon:
  <a href="https://appcenter.elementary.io/com.github.artemanufrij.findfileconflicts">
    <img src="https://appcenter.elementary.io/badge.svg" alt="Get it on AppCenter">
  </a>
</p>

<br/>

## Install from Github.

As first you need some packages
```
sudo apt install git meson
```

Clone repository and change directory
```
git clone https://github.com/artemanufrij/findfileconflicts.git
cd trimdown
```

Create **build** folder, and compile the source code
```
meson build --prefix=/usr
cd build
ninja
```

Install and start Find File Conflicts on your system
```
sudo ninja install
com.github.artemanufrij.findfileconflicts
```
