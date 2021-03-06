<script>
/**
 * Renders each stage of the pipeline mini graph.
 *
 * Given the provided endpoint will make a request to
 * fetch the dropdown data when the stage is clicked.
 *
 * Request is made inside this component to make it reusable between:
 * 1. Pipelines main table
 * 2. Pipelines table in commit and Merge request views
 * 3. Merge request widget
 * 4. Commit widget
 */

import $ from 'jquery';
import { GlLoadingIcon, GlTooltipDirective } from '@gitlab/ui';
import { __ } from '../../locale';
import Flash from '../../flash';
import axios from '../../lib/utils/axios_utils';
import eventHub from '../event_hub';
import Icon from '../../vue_shared/components/icon.vue';
import JobItem from './graph/job_item.vue';
import { PIPELINES_TABLE } from '../constants';

export default {
  components: {
    Icon,
    JobItem,
    GlLoadingIcon,
  },

  directives: {
    GlTooltip: GlTooltipDirective,
  },

  props: {
    stage: {
      type: Object,
      required: true,
    },

    updateDropdown: {
      type: Boolean,
      required: false,
      default: false,
    },

    type: {
      type: String,
      required: false,
      default: '',
    },
  },

  data() {
    return {
      isLoading: false,
      dropdownContent: '',
    };
  },

  computed: {
    dropdownClass() {
      return this.dropdownContent.length > 0
        ? 'js-builds-dropdown-container'
        : 'js-builds-dropdown-loading';
    },

    triggerButtonClass() {
      return `ci-status-icon-${this.stage.status.group}`;
    },

    borderlessIcon() {
      return `${this.stage.status.icon}_borderless`;
    },
  },

  watch: {
    updateDropdown() {
      if (this.updateDropdown && this.isDropdownOpen() && !this.isLoading) {
        this.fetchJobs();
      }
    },
  },

  updated() {
    if (this.dropdownContent.length > 0) {
      this.stopDropdownClickPropagation();
    }
  },

  methods: {
    onClickStage() {
      if (!this.isDropdownOpen()) {
        eventHub.$emit('clickedDropdown');
        this.isLoading = true;
        this.fetchJobs();
      }
    },

    fetchJobs() {
      axios
        .get(this.stage.dropdown_path)
        .then(({ data }) => {
          this.dropdownContent = data.latest_statuses;
          this.isLoading = false;
        })
        .catch(() => {
          this.closeDropdown();
          this.isLoading = false;

          Flash(__('Something went wrong on our end.'));
        });
    },

    /**
     * When the user right clicks or cmd/ctrl + click in the job name
     * the dropdown should not be closed and the link should open in another tab,
     * so we stop propagation of the click event inside the dropdown.
     *
     * Since this component is rendered multiple times per page we need to guarantee we only
     * target the click event of this component.
     */
    stopDropdownClickPropagation() {
      $(
        '.js-builds-dropdown-list button, .js-builds-dropdown-list a.mini-pipeline-graph-dropdown-item',
        this.$el,
      ).on('click', e => {
        e.stopPropagation();
      });
    },

    closeDropdown() {
      if (this.isDropdownOpen()) {
        $(this.$refs.dropdown).dropdown('toggle');
      }
    },

    isDropdownOpen() {
      return this.$el.classList.contains('show');
    },

    pipelineActionRequestComplete() {
      if (this.type === PIPELINES_TABLE) {
        // warn the table to update
        eventHub.$emit('refreshPipelinesTable');
      } else {
        // close the dropdown in mr widget
        $(this.$refs.dropdown).dropdown('toggle');
      }
    },
  },
};
</script>

<template>
  <div class="dropdown">
    <button
      id="stageDropdown"
      ref="dropdown"
      v-gl-tooltip.hover
      :class="triggerButtonClass"
      :title="stage.title"
      class="mini-pipeline-graph-dropdown-toggle js-builds-dropdown-button"
      data-toggle="dropdown"
      data-display="static"
      type="button"
      aria-haspopup="true"
      aria-expanded="false"
      @click="onClickStage"
    >
      <span :aria-label="stage.title" aria-hidden="true" class="no-pointer-events">
        <icon :name="borderlessIcon" />
      </span>
    </button>

    <div
      class="dropdown-menu mini-pipeline-graph-dropdown-menu js-builds-dropdown-container"
      aria-labelledby="stageDropdown"
    >
      <gl-loading-icon v-if="isLoading" />
      <ul v-else class="js-builds-dropdown-list scrollable-menu">
        <li v-for="job in dropdownContent" :key="job.id">
          <job-item
            :dropdown-length="dropdownContent.length"
            :job="job"
            css-class-job-name="mini-pipeline-graph-dropdown-item"
            @pipelineActionRequestComplete="pipelineActionRequestComplete"
          />
        </li>
      </ul>
    </div>
  </div>
</template>
