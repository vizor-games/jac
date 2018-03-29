# Here all sophisticated specs placed. While configuration_spec.rb file
# contains basic cases.

require_relative lib('jac/configuration')

include Jac

describe Configuration do
  context 'string evaluation' do
    context 'whole object available through c / cfg / config variable' do
      let(:conf) do
        <<-CONFIG.strip_indent
        default:
          ref: 42
          use: '\#{c.ref}'
        CONFIG
      end
      it do
        c = Configuration.read('default', conf)
        expect(c.use).to eq('42')
      end
    end

    context 'profile name available throug `c.profile`' do
      let(:conf) do
        <<-CONFIG.strip_indent
        foo:
          profile_name: "\#{c.profile.join('-')}"
        bar:
          empty: # nothing
        CONFIG
      end

      it do
        c = Configuration.read(%w[foo bar], conf)
        expect(c.profile_name).to eq(c.profile.join('-'))
      end
    end

    context 'neighbour fields can be referenced without calling any object' do
      let(:conf) do
        <<-CONFIG.strip_indent
        default:
          project: x
          projects:
            project: y
            eval_local: '\#{self["project"]}'
            eval_global: '\#{c.project}'
        CONFIG
      end

      it do
        c = Configuration.read('default', conf)
        expect(c.projects['eval_local']).to eq('y')
        expect(c.projects['eval_global']).to eq('x')
      end
    end

    context 'at top level of profile values can be referenced without c' do
      let(:conf) do
        <<-CONFIG.strip_indent
        default:
          project: sandbox-release
          project_c_eval: "\#{c.project}"
          project_self_eval: "\#{project}"
        CONFIG
      end

      it do
        c = Configuration.read('default', conf)
        # expect(c.project_c_eval).to eq(c.project)
        expect(c.project_self_eval).to eq(c.project)
      end
    end

    context 'list elements can be accessed via `self[idx]`' do
      let(:conf) do
        <<-CONFIG.strip_indent
        default:
          list: ['1', '2', '3', "\#{self[1]}", "\#{self[0]}"]
        CONFIG
      end

      it do
        c = Configuration.read('default', conf)
        expect(c.list).to match_array(%w[1 2 3 2 1])
      end
    end

    context 'profile values should shadow object methods' do
      let(:config) do
        <<-CONFIG.strip_indent
        default:
          methods:
            - GET
            - POST
          supported_methods: "\#{c.methods.join(', ')}"
        CONFIG
      end

      it do
        expect(Configuration.read('default', config).supported_methods).to eq('GET, POST')
      end
    end
  end
end
