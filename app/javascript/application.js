// Entry point for the build script in package.json.
// Core libraries (mostly just initializing)
import './src/jquery';
import {} from 'jquery-ujs'
import './src/jquery-ui';
import * as bootstrap from "bootstrap";

// Vendor
import './src/vendor/jquery-bootstrap-modal-steps.min';

// Custom
import './src/autosave';
import './src/new_care_requests_list_drag_and_drop';
import './src/clinic_finder';
import './src/clinics';
import './src/fontawesome';
import './src/multistep_modal';
import './src/table_sorting';
import './src/toggle_full_new_care_requests_list';
import './src/toggle_full_care_request_list';
import './src/tooltips';

import './src/assigned_care_requests_list_drag_and_drop';
import './src/intake_complete_list_drag_and_drop';
import './src/active_care_requests_list_drag_and_drop';
import './src/procedure_confirmed_list_drag_and_drop';
import './src/under_care_list_drag_and_drop';

// React
import './src/components/PatientDashboardForm';
