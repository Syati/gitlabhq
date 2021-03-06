# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::UrlBuilder do
  subject { described_class }

  describe '#build' do
    it 'delegates to the class method' do
      expect(subject).to receive(:build).with(:foo, bar: :baz)

      subject.instance.build(:foo, bar: :baz)
    end
  end

  describe '.build' do
    using RSpec::Parameterized::TableSyntax

    where(:factory, :path_generator) do
      :project           | ->(project)       { "/#{project.full_path}" }
      :commit            | ->(commit)        { "/#{commit.project.full_path}/-/commit/#{commit.id}" }
      :issue             | ->(issue)         { "/#{issue.project.full_path}/-/issues/#{issue.iid}" }
      :merge_request     | ->(merge_request) { "/#{merge_request.project.full_path}/-/merge_requests/#{merge_request.iid}" }
      :project_milestone | ->(milestone)     { "/#{milestone.project.full_path}/-/milestones/#{milestone.iid}" }
      :project_snippet   | ->(snippet)       { "/#{snippet.project.full_path}/snippets/#{snippet.id}" }
      :project_wiki      | ->(wiki)          { "/#{wiki.container.full_path}/-/wikis/home" }
      :ci_build          | ->(build)         { "/#{build.project.full_path}/-/jobs/#{build.id}" }
      :design            | ->(design)        { "/#{design.project.full_path}/-/design_management/designs/#{design.id}/raw_image" }

      :group             | ->(group)         { "/groups/#{group.full_path}" }
      :group_milestone   | ->(milestone)     { "/groups/#{milestone.group.full_path}/-/milestones/#{milestone.iid}" }

      :user              | ->(user)          { "/#{user.full_path}" }
      :personal_snippet  | ->(snippet)       { "/snippets/#{snippet.id}" }
      :wiki_page         | ->(wiki_page)     { "#{wiki_page.wiki.wiki_base_path}/#{wiki_page.slug}" }

      :note_on_commit                      | ->(note) { "/#{note.project.full_path}/-/commit/#{note.commit_id}#note_#{note.id}" }
      :diff_note_on_commit                 | ->(note) { "/#{note.project.full_path}/-/commit/#{note.commit_id}#note_#{note.id}" }
      :discussion_note_on_commit           | ->(note) { "/#{note.project.full_path}/-/commit/#{note.commit_id}#note_#{note.id}" }
      :legacy_diff_note_on_commit          | ->(note) { "/#{note.project.full_path}/-/commit/#{note.commit_id}#note_#{note.id}" }

      :note_on_issue                       | ->(note) { "/#{note.project.full_path}/-/issues/#{note.noteable.iid}#note_#{note.id}" }
      :discussion_note_on_issue            | ->(note) { "/#{note.project.full_path}/-/issues/#{note.noteable.iid}#note_#{note.id}" }

      :note_on_merge_request               | ->(note) { "/#{note.project.full_path}/-/merge_requests/#{note.noteable.iid}#note_#{note.id}" }
      :diff_note_on_merge_request          | ->(note) { "/#{note.project.full_path}/-/merge_requests/#{note.noteable.iid}#note_#{note.id}" }
      :discussion_note_on_merge_request    | ->(note) { "/#{note.project.full_path}/-/merge_requests/#{note.noteable.iid}#note_#{note.id}" }
      :legacy_diff_note_on_merge_request   | ->(note) { "/#{note.project.full_path}/-/merge_requests/#{note.noteable.iid}#note_#{note.id}" }

      :note_on_project_snippet             | ->(note) { "/#{note.project.full_path}/snippets/#{note.noteable_id}#note_#{note.id}" }
      :discussion_note_on_project_snippet  | ->(note) { "/#{note.project.full_path}/snippets/#{note.noteable_id}#note_#{note.id}" }
      :discussion_note_on_personal_snippet | ->(note) { "/snippets/#{note.noteable_id}#note_#{note.id}" }
      :note_on_personal_snippet            | ->(note) { "/snippets/#{note.noteable_id}#note_#{note.id}" }
    end

    with_them do
      let(:object) { build_stubbed(factory) }
      let(:path) { path_generator.call(object) }

      it 'returns the full URL' do
        expect(subject.build(object)).to eq("#{Gitlab.config.gitlab.url}#{path}")
      end

      it 'returns only the path if only_path is given' do
        expect(subject.build(object, only_path: true)).to eq(path)
      end
    end

    context 'when passing a commit without a project' do
      let(:commit) { build_stubbed(:commit) }

      it 'returns an empty string' do
        allow(commit).to receive(:project).and_return(nil)

        expect(subject.build(commit)).to eq('')
      end
    end

    context 'when passing a commit note without a project' do
      let(:note) { build_stubbed(:note_on_commit) }

      it 'returns an empty string' do
        allow(note).to receive(:project).and_return(nil)

        expect(subject.build(note)).to eq('')
      end
    end

    context 'when passing a Snippet' do
      let(:snippet) { build_stubbed(:personal_snippet) }

      it 'returns a raw snippet URL if requested' do
        url = subject.build(snippet, raw: true)

        expect(url).to eq "#{Gitlab.config.gitlab.url}/snippets/#{snippet.id}/raw"
      end
    end

    context 'when passing a DesignManagement::Design' do
      let(:design) { build_stubbed(:design) }

      it 'uses the given ref and size in the URL' do
        url = subject.build(design, ref: 'feature', size: 'small')

        expect(url).to eq "#{Settings.gitlab['url']}/#{design.project.full_path}/-/design_management/designs/#{design.id}/feature/resized_image/small"
      end
    end

    context 'when passing an unsupported class' do
      let(:object) { Object.new }

      it 'raises an exception' do
        expect { subject.build(object) }.to raise_error(NotImplementedError)
      end
    end

    context 'when passing a batch loaded model' do
      let(:project) { build_stubbed(:project) }
      let(:object) do
        BatchLoader.for(:project).batch do |batch, loader|
          batch.each { |_| loader.call(:project, project) }
        end
      end

      it 'returns the URL for the real object' do
        expect(subject.build(object, only_path: true)).to eq("/#{project.full_path}")
      end
    end
  end
end
