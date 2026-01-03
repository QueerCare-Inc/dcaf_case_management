import React, { useState, useMemo, useEffect } from "react";
import Input from './Input'
import Select from './Select'
import Tooltip from './Tooltip'
import mount from "../mount";
import { usei18n, useFetch, useFlash, useDebounce } from "../hooks";

export default NewCareAddressForm = ({ 
    procedure, 
    careAddressForm,
    newCareAddressPath, 
    formAuthenticityToken 
}) => {
  const i18n = usei18n();
  const { put } = useFetch(); // Changed to put for updates
  // const { post } = useFetch(); // Added post for creating new records
  const flash = useFlash();
  const { debounce, cleanupDebounce } = useDebounce();

  const [newCareAddressData, setFormData] = useState(careAddressForm)

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData((prevData) => ({
      ...prevData,
      [name]: value,
    }));
  };

  const debouncedHandleChange = useMemo((params) => {
      return debounce(handleChange, 300)
    }, []);

    // Stop the invocation of the debounced function after unmounting
    useEffect(() => {
      return () => {
        cleanupDebounce();
      }
    }, []);


  const handleSubmit = async (e) => {
    e.preventDefault();

    const response = await post(newCareAddressPath, {
      ...newCareAddressData,
      authenticity_token: formAuthenticityToken,
    });

    flash.render(response.flash);

    if (response.success) {
      // Clear the form after successful submission
      setFormData({
        street_address: "",
        city: "",
        state: "",
        zip: "",
        phone_number: "",
        qc_house: false,
        accessibility_options: [],
        start_date: "",
        end_date: "",
        confirmed: false,
      });
    }
  };

  const debouncedHandleSubmit = useMemo((params) => {
      return debounce(handleSubmit, 300)
    }, []);

    // Stop the invocation of the debounced function after unmounting
    useEffect(() => {
      return () => {
        cleanupDebounce();
      }
    }, []);

  return (
    <form
      id="new_care_address_form"
      action={newCareAddressPath}
      method="post"
      data-remote="true"
      onSubmit={debouncedHandleSubmit}
      className="grid grid-columns-2 gap-4"
    >
      <Input
        id="care_address_street_address"
        name="street_address"
        label={i18n.t("care_address.street_address")}
        value={newCareAddressData.street_address}
        onChange={(e) => debouncedHandleChange({ street_address: e.target.value })}
      />

      <Input
        id="care_address_city"
        name="city"
        label={i18n.t("care_address.city")}
        value={newCareAddressData.city}
        onChange={(e) => debouncedHandleChange({ city: e.target.value })}
      />

      <Input
        id="care_address_state"
        name="state"
        label={i18n.t("care_address.state")}
        value={newCareAddressData.state}
        onChange={(e) => debouncedHandleChange({ state: e.target.value })}
      />

      <Input
        id="care_address_zip"
        name="zip"
        label={i18n.t("care_address.zip")}
        value={newCareAddressData.zip}
        onChange={(e) => debouncedHandleChange({ zip: e.target.value })}
      />

      <Input
        id="care_address_phone_number"
        name="phone_number"
        label={i18n.t("care_address.phone_number")}
        value={newCareAddressData.phone_number}
        onChange={(e) => debouncedHandleChange({ phone_number: e.target.value })}
      />

      <Input
        id="care_address_qc_house"
        name="qc_house"
        label={i18n.t("care_address.qc_housing")}
        type="boolean"
        value={newCareAddressData.qc_house}
        onChange={(e) => debouncedHandleChange({ qc_house: e.target.value })}
      />

      <Input
        id="care_address_accessibility_options"
        name="accessibility_options"
        label={i18n.t("care_address.accessibility_options")}
        value={newCareAddressData.accessibility_options}
        onChange={(e) => debouncedHandleChange({ accessibility_options: e.target.value })}
      />

      <Input
        id="care_address_start_date"
        name="start_date"
        label={i18n.t("care_address.start_date")}
        type="date"
        value={newCareAddressData.start_date}
        onChange={(e) => debouncedHandleChange({ start_date: e.target.value })}
      />

      <Input
        id="care_address_end_date"
        name="end_date"
        label={i18n.t("care_address.end_date")}
        type="date"
        value={newCareAddressData.end_date}
        onChange={(e) => debouncedHandleChange({ end_date: e.target.value })}
      />

      <Input
        id="care_address_confirmed"
        name="confirmed"
        label={i18n.t("care_address.confirmed")}
        type="boolean"
        value={newCareAddressData.confirmed}
        onChange={(e) => debouncedHandleChange({ confirmed: e.target.value })}
      />

      <button type="submit" className="btn btn-primary">
        {i18n.t("care_address.add_address")}
      </button>
    </form>
  )
};

mount({
  NewCareAddressForm,
});
