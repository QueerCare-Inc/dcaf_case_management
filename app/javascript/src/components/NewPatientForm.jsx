import React, { useState } from "react";
import Input from "./Input";
import { usei18n, useFetch, useFlash } from "../hooks";

const NewPatientForm = ({
  patientPath,
  formAuthenticityToken,
  onSuccess,
  procedureTypeOptions,
  regionOptions,
  currentRegionId,
}) => {
  const i18n = usei18n();
  const { post } = useFetch();
  const flash = useFlash();

  const [formData, setFormData] = useState({
    name: "",
    procedure_date: "",
    primary_phone: "",
    pronouns: "",
    email: "",
    procedure_type: "",
    region_id: currentRegionId || "",
  });

  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setFormData((prevData) => ({ ...prevData, [name]: value }));
  };

  const handleSubmit = async (e) => {
    e.preventDefault();

    const data = await post(patientPath, {
      ...formData,
      authenticity_token: formAuthenticityToken,
    });

    if (data.success) {
      flash.render(data.flash);
      setFormData({
        name: "",
        procedure_date: "",
        primary_phone: "",
        pronouns: "",
        email: "",
        procedure_type: "",
        region_id: currentRegionId || "",
      }); // Clear the form
      if (onSuccess) onSuccess(); // Notify parent component of success
    } else {
      flash.render({ error: i18n.t("patient.dashboard.submit_error") });
    }
  };

  return (
    <form id="new_patient_form" onSubmit={handleSubmit}>
      <Input
        id="patient_name"
        name="name"
        label={i18n.t("patient.shared.name")}
        value={formData.name}
        required
        onChange={handleInputChange}
      />

      <Input
        id="patient_procedure_date"
        name="procedure_date"
        label={i18n.t("patient.shared.appt_date")}
        type="date"
        value={formData.procedure_date}
        onChange={handleInputChange}
      />

      <Input
        id="patient_primary_phone"
        name="primary_phone"
        label={i18n.t("patient.dashboard.phone_number")}
        value={formData.primary_phone}
        onChange={handleInputChange}
      />

      <Input
        id="patient_pronouns"
        name="pronouns"
        label={i18n.t("activerecord.attributes.patient.pronouns")}
        value={formData.pronouns}
        onChange={handleInputChange}
      />

      <Input
        id="patient_email"
        name="email"
        label={i18n.t("common.email")}
        type="email"
        value={formData.email}
        required
        onChange={handleInputChange}
      />

      <div className="form-group">
        <label htmlFor="patient_procedure_type">
          {i18n.t("common.procedure_type")}
        </label>
        <select
          id="patient_procedure_type"
          name="procedure_type"
          value={formData.procedure_type}
          required
          onChange={handleInputChange}
          className="form-control"
        >
          <option value="">{i18n.t("common.select_option")}</option>
          {procedureTypeOptions.map((option) => (
            <option key={option.value} value={option.value}>
              {option.label}
            </option>
          ))}
        </select>
      </div>

      <div className="form-group">
        <label htmlFor="patient_region_id">
          {i18n.t("common.region")}
        </label>
        <select
          id="patient_region_id"
          name="region_id"
          value={formData.region_id}
          required
          onChange={handleInputChange}
          className="form-control"
        >
          {regionOptions.map((option) => (
            <option key={option.value} value={option.value}>
              {option.label}
            </option>
          ))}
        </select>
      </div>

      <button type="submit" className="btn btn-primary">
        <i className="fas fa-plus-circle" aria-hidden="true"></i> {i18n.t("patient.new.add_button")}
      </button>
    </form>
  );
};

export default NewPatientForm;