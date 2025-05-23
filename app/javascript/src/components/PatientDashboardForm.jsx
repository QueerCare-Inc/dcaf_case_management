import React, { useState, useMemo, useEffect } from "react";
import Input from './Input'
import Select from './Select'
import Tooltip from './Tooltip'
import mount from "../mount";
import { usei18n, useFetch, useFlash, useDebounce } from "../hooks";

export default PatientDashboardForm = ({
  patient,
  weeksOptions,
  daysOptions,
  // initialCallDate,
  statusHelpText,
  isAdmin,
  patientPath,
  formAuthenticityToken
}) => {
  const i18n = usei18n();
  const { put } = useFetch();
  const flash = useFlash();
  const { debounce, cleanupDebounce } = useDebounce();

  const [patientData, setPatientData] = useState(patient)

  const statusTooltip = statusHelpText ? <Tooltip text={statusHelpText} /> : null

  const autosave = async (updatedData) => {
    const updatedPatientData = { ...patientData, ...updatedData }
    setPatientData(updatedPatientData)

    const putData = {
      name: updatedPatientData.name,
      procedure_date: updatedPatientData.procedure_date,
      primary_phone: updatedPatientData.primary_phone,
      pronouns: updatedPatientData.pronouns,
    }

    const data = await put(patientPath, { ...putData, authenticity_token: formAuthenticityToken })
    flash.render(data.flash)
    if (data.patient) {
      setPatientData(data.patient)
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
      id="patient_dashboard_form"
      action={patientPath}
      data-remote="true" method="post"
      className="grid grid-columns-3 grid-rows-2"
    >
      <Input
        id="patient_name"
        name="patient[name]"
        label={i18n.t('patient.shared.name')}
        value={patientData.name}
        required
        onChange={(e) => debouncedAutosave({ name: e.target.value })}
      />

      <Input
        id="patient_procedure_date"
        name="patient[procedure_date]"
        label={i18n.t('patient.shared.appt_date')}
        type="date"
        value={patientData.procedure_date}
        onChange={e => debouncedAutosave({ procedure_date: e.target.value })}
      />

      <Input
        id="patient_primary_phone"
        name="patient[primary_phone]"
        label={i18n.t('patient.dashboard.phone')}
        value={patientData.primary_phone_display}
        onChange={e => debouncedAutosave({ primary_phone: e.target.value })}
      />

      <div className="grid grid-columns-2">
        <Input
          id="patient_pronouns"
          name="patient[pronouns]"
          label={i18n.t('activerecord.attributes.patient.pronouns')}
          value={patientData.pronouns}
          onChange={e => debouncedAutosave({ pronouns: e.target.value })}
        />

        <Input
          id="patient_status_display"
          label={i18n.t('patient.shared.status')}
          value={patientData.status}
          className="form-control-plaintext"
          tooltip={statusTooltip}
          onChange={e => debouncedAutosave({ status: e.target.value })}
        />
      </div>


      <div>
        {isAdmin && (
          <>
            <label>{i18n.t('patient.dashboard.delete_label')}</label>
            <div>
              <a className="btn btn-danger" data-confirm={i18n.t('patient.dashboard.confirm_del', { name: patient.name })} rel="nofollow" data-method="delete" href={patientPath}>{i18n.t('patient.dashboard.delete')}</a>
            </div>
          </>
        )}
      </div>
    </form>
  )
};

mount({
  PatientDashboardForm,
});
