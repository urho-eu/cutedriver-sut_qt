@echo off
del /F /Q pkg\
cmd /c "gem uninstall cutedriver-sut-qt-plugin"
cmd /c "gem build cutedriver-sut_qt.gemspec"
cmd /c "gem install cutedriver-sut* --LOCAL --no-ri --no-rdoc"
