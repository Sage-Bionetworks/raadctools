from setuptools import setup, find_packages

setup(name='submitRAADC2',
      version='0.0.1',
      description='RAAD2 Submission Wrapper',
      url='https://github.roche.com/RAADC2019/submitRAADC2',
      author='Thomas Yu',
      author_email='thomas.yu@sagebase.org',
      license='MIT',
      packages=find_packages(),
      package_data={
        'submitRAADC2': [
            'data/*'
        ]
    },
      zip_safe=False,
      entry_points = {
        'console_scripts': ['submitRAADC2 = submitRAADC2.submit:main']},
      install_requires=[
        'pandas>=0.20.0',
        'rpy2',
        'tzlocal',
        'synapseclient'])
