// import NdrfBanner from "../../assets/ndrf_banner.svg"
import MainLogo from "../../assets/MainLogo.png";
import { FaEnvelope, FaPhoneAlt } from "react-icons/fa";
import "./footer.css";
// import { useTranslation } from "react-i18next";
function Footer() {
  // const { t } = useTranslation();
  return (
    <>
      <div className="banner">
        {/* <img src={NdrfBanner} alt="banner.svg" className="banner_img" /> */}
      </div>
      <footer className="footer-container">
        <div className="footer-left">
          <img src={MainLogo} alt="mainLogo.svg" />
          <p className="footer-description">{t("footer_description")}</p>
          <div className="contact-icons">
            <FaEnvelope />
            <FaPhoneAlt />
          </div>
        </div>
        <div className="footer-middle">
          <div>
            <h4>{t("footer_middle_div_1")}</h4>
            <ul>
              <li>{t("footer_middle_div_2")}</li>
              <li>{t("footer_middle_div_3")}</li>
              <li>{t("footer_middle_div_4")}</li>
              <li>{t("footer_middle_div_5")}</li>
            </ul>
          </div>
          <div>
            <h4>{t("footer_middle_div_5")}</h4>
            <ul>
              <li>{t("footer_middle_div_7")}</li>
              <li>{t("footer_middle_div_8")}</li>
              <li>{t("footer_middle_div_9")}</li>
            </ul>
          </div>
        </div>
        <div className="footer-right">
          <p>{t("footer_middle_div_10")}: +91-9711077372</p>
        </div>
      </footer>
    </>
  );
}

export default Footer;
