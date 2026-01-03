import React, { useState, useMemo, useEffect } from "react";
import Input from './Input'
import Select from './Select'
import Tooltip from './Tooltip'
import mount from "../mount";
import { usei18n, useFetch, useFlash, useDebounce } from "../hooks";

export default PatientCareRequestDashboardForm = ({
  care_request_entry,
  weeksOptions,
  daysOptions,
  // initialCallDate,
  statusHelpText,
  isAdmin,
  isCareCoordinator,
  isCoordAdmin,
  markeIntakeCompletePath,
  patientPath,
  formAuthenticityToken
}) => {
  const i18n = usei18n();
  const { put } = useFetch();
  const flash = useFlash();
  const { debounce, cleanupDebounce } = useDebounce();

  const [careRequestEntryData, setCareRequestEntryData] = useState(care_request_entry)

  const statusTooltip = statusHelpText ? <Tooltip text={statusHelpText} /> : null

  const autosave = async (updatedData) => {
    const updatedCareRequestEntryData = { ...careRequestEntryData, ...updatedData }
    setCareRequestEntryData(updatedCareRequestEntryData)

    const putData = {
      name: updatedCareRequestEntryData.name,
      procedure_date: updatedCareRequestEntryData.procedure_date,
      primary_phone: updatedCareRequestEntryData.primary_phone,
      pronouns: updatedCareRequestEntryData.pronouns,
      email: updatedCareRequestEntryData.email,
      intake_date: updatedCareRequestEntryData.intake_date,
      care_coordinator: updatedCareRequestEntryData.care_coordinator,
      procedure_date: updatedCareRequestEntryData.procedure_date,
      care_status: updatedCareRequestEntryData.care_status
    }

    const data = await put(patientPath, { ...putData, authenticity_token: formAuthenticityToken })
    flash.render(data.flash)
    if (data.patient) {
      setCareRequestEntryData(data.patient)
    }
  }

  const debouncedAutosave = useMemo((params) => {
    return debounce(autosave, 300)
  }, []);

  // Stop the invocation of the debounced function after unmounting
  useEffect(() => {
    return () => {
      cleanupDebounce();
    }
  }, []);

  return (
    <form
      id="patient_care_request_dashboard_form"
      action={patientPath}
      data-remote="true" method="post"
      className="grid grid-columns-4 grid-rows-2"
    >
      <Input
        id="patient_name"
        name="care_request_entry[name]"
        label={i18n.t('activerecord.attributes.patient.name')}
        value={careRequestEntryData.name}
        required
        onChange={(e) => debouncedAutosave({ name: e.target.value })}
      />

      <Input
        id="patient_primary_phone"
        name="care_request_entry[primary_phone]"
        label={i18n.t('activerecord.attributes.patient.phone_number')}
        value={careRequestEntryData.primary_phone}
        onChange={e => debouncedAutosave({ primary_phone: e.target.value })}
      />

      <Input
        id="patient_pronouns"
        name="care_request_entry[pronouns]"
        label={i18n.t('activerecord.attributes.patient.pronouns')}
        value={careRequestEntryData.pronouns}
        onChange={e => debouncedAutosave({ pronouns: e.target.value })}
      />

      <Input
        id="patient_email"
        name="care_request_entry[email]"
        label={i18n.t('activerecord.attributes.patient.email')}
        value={careRequestEntryData.email}
        onChange={e => debouncedAutosave({ email: e.target.value })}
      />

      <Input
        id="patient_intake_date"
        name="care_request_entry[intake_date]"
        label={i18n.t('activerecord.attributes.patient.intake_date')}
        type="date"
        value={careRequestEntryData.intake_date}
        onChange={e => debouncedAutosave({ intake_date: e.target.value })}
      />

      <Input
        id="care_coordinator"
        name="care_request_entry[care_coordinator]"
        label={i18n.t('activerecord.attributes.patient.care_coordinator')}
        value={careRequestEntryData.care_coordinator}
        onChange={e => debouncedAutosave({ care_coordinator: e.target.value })}
      />

      <Input
        id="patient_procedure_date"
        name="care_request_entry[procedure_date]"
        label={i18n.t('activerecord.attributes.patient.procedure_date')}
        type="date"
        value={careRequestEntryData.procedure_date}
        onChange={e => debouncedAutosave({ procedure_date: e.target.value })}
      />

      <Input
        id="patient_status_display"
        label={i18n.t('patient.shared.status')}
        value={careRequestEntryData.care_status}
        className="form-control-plaintext"
        tooltip={statusTooltip}
        onChange={e => debouncedAutosave({ care_status: e.target.value })}
      />

      <div>
        {isAdmin && (
          <>
            <label>{i18n.t('patient.dashboard.delete_label')}</label>
            <div>
              <a className="btn btn-danger" data-confirm={i18n.t('patient.dashboard.confirm_del', { name: care_request_entry.name })} rel="nofollow" data-method="delete" href={patientPath}>{i18n.t('patient.dashboard.delete')}</a>
            </div>
          </>
        )}
      </div>

      <div>
        {(isAdmin || isCareCoordinator || isCoordAdmin) && (careRequestEntryData.care_status == 'coordinator_assigned') && (
          <>
            <label>{i18n.t('patient.dashboard.intake_complete')}</label>
            <div>
              <a className="btn btn-success" data-confirm={i18n.t('patient.dashboard.confirm_intake_complete', { name: care_request_entry.name })} rel="nofollow" data-method="patch" href={markeIntakeCompletePath}>{i18n.t('patient.dashboard.intake_complete')}</a>
            </div>
          </>
        )}
      </div>
    </form>
  )
};

mount({
  PatientCareRequestDashboardForm,
});
