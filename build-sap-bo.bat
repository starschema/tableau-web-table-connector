SET BOOTSTRAP_DIR=.\dist\bootstrap\3.3.5
SET JQUERY_DIR=.\dist\jquery\1.11.1

echo %BOOTSTRAP_DIR%
echo %JQUERY_DIR%
mkdir %BOOTSTRAP_DIR%
xcopy /E /Q /Y resources\bootstrap-3.3.5-dist\* %BOOTSTRAP_DIR%

mkdir %JQUERY_DIR%
xcopy /E /Q /Y resources\jquery\1.11.1\* %JQUERY_DIR%

xcopy /E /Q /Y resources\tableau-wdc-js\tableauwdc-1.1.0.js .\dist
xcopy /E /Q /Y resources\sapbo.html .\dist
node node_modules\browserify\bin\cmd.js --extension=".coffee"  coffee\sap_bo\sap_bo_connector.coffee > dist\twdc_sap_bo_connector.js
