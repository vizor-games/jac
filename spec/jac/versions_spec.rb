require_relative lib('jac/versions')

describe Versions do
  describe '::match' do
    context 'when version rule starts with =' do
      context 'when versions don\'t match' do
        it { expect(Versions.match('1.0.2', '=1.0.3')).to be_nil }
      end

      context 'when versions match exactly' do
        it { expect(Versions.match('1.0.2', '=1.0.2')).to eq('1.0.2') }
      end
    end

    context 'when version rule starts with >=' do
      context 'when version is lower than target' do
        it { expect(Versions.match('1.0.2', '>=1.0.3')).to be_nil }
      end

      context 'when version is equals target version' do
        it { expect(Versions.match('1.0.2', '>=1.0.2')).to eq('1.0.2') }
      end

      context 'when version is greater than target' do
        it { expect(Versions.match('1.0.2', '>=1.0.0')).to eq('1.0.2') }
      end
    end

    context 'when version rule starts with <=' do
      context 'when version is lower than target' do
        it { expect(Versions.match('1.0.2', '<=1.0.3')).to eq('1.0.2') }
      end

      context 'when version is equals target' do
        it { expect(Versions.match('1.0.2', '<=1.0.2')).to eq('1.0.2') }
      end

      context 'when version is greater than target' do
        it { expect(Versions.match('1.0.2', '<=1.0.0')).to be_nil }
      end
    end
  end
end
