import Vue from 'vue';
import Vuex from 'vuex';
import notesModule from '~/notes/stores/modules';
import diffsModule from '~/diffs/store/modules';
import batchCommentsModule from 'ee/batch_comments/stores/modules/batch_comments';
import mrPageModule from './modules';

Vue.use(Vuex);

export const createStore = () =>
  new Vuex.Store({
    modules: {
      page: mrPageModule,
      notes: notesModule(),
      diffs: diffsModule(),
<<<<<<< HEAD
      batchComments: batchCommentsModule(),
=======
>>>>>>> upstream/master
    },
  });

export default createStore();
