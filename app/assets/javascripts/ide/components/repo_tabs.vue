<script>
import { mapActions } from 'vuex';
import RepoTab from './repo_tab.vue';
import router from '../ide_router';

export default {
  components: {
    RepoTab,
  },
  props: {
    activeFile: {
      type: Object,
      required: true,
    },
    files: {
      type: Array,
      required: true,
    },
    viewer: {
      type: String,
      required: true,
    },
  },
  methods: {
    ...mapActions(['updateViewer', 'removePendingTab']),
    openFileViewer(viewer) {
      this.updateViewer(viewer);

      if (this.activeFile.pending) {
        return this.removePendingTab(this.activeFile).then(() => {
          router.push(`/project${this.activeFile.url}`);
        });
      }

      return null;
    },
  },
};
</script>

<template>
  <div class="multi-file-tabs">
    <ul ref="tabsScroller" class="list-unstyled gl-mb-0">
      <repo-tab v-for="tab in files" :key="tab.key" :tab="tab" />
    </ul>
  </div>
</template>
