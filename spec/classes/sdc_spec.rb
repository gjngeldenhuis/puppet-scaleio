require File.expand_path(File.join(File.dirname(__FILE__),'../spec_helper'))

describe 'scaleio::sdc', :type => 'class' do
  let(:facts){
    {
      :interfaces => 'eth0',
    }
  }
  # mdm ips are configured in hiera
  describe 'with standard' do
    #it { should compile.with_all_deps }
    it { should contain_class('scaleio') }
    it { should contain_package('EMC-ScaleIO-sdc').with_ensure('installed') }

    it { should contain_exec('scaleio::sdc_add_mdm').with(
      :command  => '/bin/emc/scaleio/drv_cfg --add_mdm --ip 1.2.3.4,1.2.3.5 --file /bin/emc/scaleio/drv_cfg.txt',
      :unless   => 'grep -qE \'^mdm 1.2.3.4,1.2.3.5$\' /bin/emc/scaleio/drv_cfg.txt',
      :require  => 'Package[EMC-ScaleIO-sdc]'
    )}
  end
  context 'with a missing primary ip' do
    let(:pre_condition) {
      "class{'scaleio': primary_mdm_ip => '' }"
    }
    it { expect { subject.call('fail') }.to raise_error(Puppet::Error) }
  end
  context 'with a missing secondary ip' do
    let(:pre_condition) {
      "class{'scaleio': secondary_mdm_ip => '' }"
    }
    it { expect { subject.call('fail') }.to raise_error(Puppet::Error) }
  end
end
